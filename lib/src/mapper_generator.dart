import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:collection/collection.dart';

import 'annotations.dart';

class MapperGenerator extends GeneratorForAnnotation<Mapper> {
  final _mappingChecker =
  TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#Mapping');

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement || !element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@Mapper can only be used on abstract classes',
        element: element,
      );
    }

    final className = element.name;
    final implName =
        annotation.peek('implementationName')?.stringValue ?? '${className}Impl';

    final buffer = StringBuffer();
    buffer.writeln('class $implName extends $className {');

    final genericMap = _collectGenericTypes(element);

    for (final method in _getAllAbstractMethods(element)) {
      _generateMethod(buffer, method, genericMap);
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  void _generateMethod(
      StringBuffer buffer,
      MethodElement method,
      Map<TypeParameterElement, DartType> generics,
      ) {
    final sourceParam = method.formalParameters.first;
    final sourceType = _resolveType(sourceParam.type, generics);
    final targetType = _resolveType(method.returnType, generics);

    final sourceFields = _getFields(sourceType);
    final targetFields = _getFields(targetType);

    buffer.writeln(
      '  @override ${targetType.getDisplayString()} ${method.name}(${sourceType.getDisplayString()} ${sourceParam.name}) {',
    );

    final constructorParams = <String>[];

    for (final targetField in targetFields) {
      final mapping = _getMappingForField(method, targetField);

      if (mapping?.ignore == true) continue;

      final sourceName = mapping?.source ?? targetField.name;
      final sourceField =
      sourceFields.firstWhereOrNull((f) => f.name == sourceName);

      if (sourceField == null) continue;

      final valueExpr = _buildValueExpression(
        rule: mapping,
        sourceParam: sourceParam.name!,
        sourceField: sourceField,
        targetField: targetField,
      );

      constructorParams.add('${targetField.name}: $valueExpr');
    }

    buffer.writeln(
      '    return ${targetType.getDisplayString()}(${constructorParams.join(', ')});',
    );
    buffer.writeln('  }');
  }

  String _buildValueExpression({
    required _MappingRule? rule,
    required String sourceParam,
    required FieldElement sourceField,
    required FieldElement targetField,
  }) {
    final srcExpr = '$sourceParam.${sourceField.name}';

    // ---------- Converter ----------
    if (rule?.converter != null) {
      final convName = rule!.converter!.getDisplayString();
      final convExpr = '${convName}().convert($srcExpr)';

      if (rule.condition != null) {
        return '(${_replaceValue(rule.condition!, srcExpr)}) ? $convExpr : null';
      }
      return convExpr;
    }

    // ---------- Expression ----------
    if (rule?.expression != null) {
      var expr = _replaceValue(rule!.expression!, srcExpr);

      // nullable-safe optimization
      if (targetField.type.nullabilitySuffix != NullabilitySuffix.none &&
          expr.contains('$srcExpr.')) {
        expr = expr.replaceFirst('$srcExpr.', '$srcExpr?.');
        return expr;
      }

      if (rule.condition != null) {
        return '(${_replaceValue(rule.condition!, srcExpr)}) ? $expr : null';
      }
      return expr;
    }

    // ---------- Condition only ----------
    if (rule?.condition != null) {
      return '(${_replaceValue(rule!.condition!, srcExpr)}) ? $srcExpr : null';
    }

    // ---------- Default smart cast ----------
    return _smartCast(
      sourceParam,
      sourceField.name!,
      sourceField.type,
      targetField.type,
    );
  }

  String _replaceValue(String input, String srcExpr) {
    return input.replaceAll('value', srcExpr);
  }

  String _smartCast(
      String sourceParam,
      String fieldName,
      DartType sourceType,
      DartType targetType,
      ) {
    final src = sourceType.getDisplayString();
    final tgt = targetType.getDisplayString();
    final isSourceNullable =
        sourceType.nullabilitySuffix != NullabilitySuffix.none;

    final expr = '$sourceParam.$fieldName';

    if (src == tgt) return expr;
    if (src == 'String' && tgt == 'int') return 'int.tryParse($expr)';
    if (src == 'String' && tgt == 'double') return 'double.tryParse($expr)';
    if ((src == 'int' || src == 'double') && tgt == 'String') {
      return isSourceNullable ? '$expr?.toString()' : '$expr.toString()';
    }
    if (src == 'bool' && tgt == 'String') {
      return isSourceNullable ? '$expr?.toString()' : '$expr.toString()';
    }
    if (src == 'String' && tgt == 'bool') {
      return isSourceNullable
          ? '($expr != null ? $expr == "true" : null)'
          : '($expr == "true")';
    }

    // no forced cast
    return expr;
  }

  _MappingRule? _getMappingForField(
      MethodElement method, FieldElement targetField) {
    final mappingAnnotations =
    _mappingChecker.annotationsOf(method, throwOnUnresolved: false);

    for (final annotation in mappingAnnotations) {
      final reader = ConstantReader(annotation);
      final target = reader.read('target').stringValue;
      if (target != targetField.name) continue;

      return _MappingRule(
        target: target,
        source: reader.peek('source')?.stringValue,
        ignore: reader.peek('ignore')?.boolValue ?? false,
        expression: reader.peek('expression')?.stringValue,
        converter: reader.peek('converter')?.typeValue,
        condition: reader.peek('condition')?.stringValue,
      );
    }
    return null;
  }

  Map<TypeParameterElement, DartType> _collectGenericTypes(
      ClassElement element) {
    final map = <TypeParameterElement, DartType>{};

    void collect(InterfaceType? type) {
      if (type == null) return;
      final params = type.element.typeParameters;
      final args = type.typeArguments;

      for (var i = 0; i < params.length; i++) {
        map[params[i]] = args[i];
      }
      collect(type.superclass);
    }

    collect(element.thisType);
    return map;
  }

  DartType _resolveType(
      DartType type,
      Map<TypeParameterElement, DartType> generics,
      ) =>
      type is TypeParameterType ? generics[type.element] ?? type : type;

  List<FieldElement> _getFields(DartType type) {
    if (type is! InterfaceType) return const [];
    return type.element.fields
        .where((f) => f.isPublic && !f.isStatic)
        .toList();
  }

  Iterable<MethodElement> _getAllAbstractMethods(ClassElement clazz) sync* {
    final seenNames = <String>{};

    Iterable<MethodElement> collect(ClassElement c) sync* {
      for (final m in c.methods.where((m) => m.isAbstract)) {
        // فقط بر اساس نام متد dedupe کن
        if (seenNames.add(m.name!)) {
          yield m;
        }
      }

      final supertype = c.supertype;
      if (supertype != null &&
          !supertype.isDartCoreObject &&
          !supertype.element.library.isInSdk) {
        yield* collect(supertype.element as ClassElement);
      }
    }

    yield* collect(clazz);
  }
}


class _MappingRule {
  final String target;
  final String? source;
  final bool ignore;
  final String? expression;
  final DartType? converter;
  final String? condition;

  _MappingRule({
    required this.target,
    this.source,
    this.ignore = false,
    this.expression,
    this.converter,
    this.condition,
  });
}
