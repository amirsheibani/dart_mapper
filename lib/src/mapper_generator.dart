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
  final _ignoreChecker =
  TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#Ignore');
  final _customChecker =
  TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#CustomMapping');

  @override
  String generateForAnnotatedElement(
      covariant Element element,
      ConstantReader annotation,
      BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          '@Mapper can only be used on classes', element: element);
    }
    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
          '@Mapper class must be abstract', element: element);
    }

    final className = element.name;
    final implName =
        annotation.peek('implementationName')?.stringValue ?? '${className}Impl';
    final buffer = StringBuffer();

    buffer.writeln('class $implName extends $className {');

    final methods = _getAllAbstractMethods(element).toList();
    for (final method in methods) {
      _generateMethod(buffer, method);
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  void _generateMethod(StringBuffer buffer, MethodElement method) {
    final params = method.formalParameters;
    if (params.length != 1) {
      throw InvalidGenerationSourceError(
          'Mapper methods must have exactly one parameter',
          element: method);
    }

    final sourceParam = params.first;
    final sourceFields = _getFields(sourceParam.type);
    final targetType = method.returnType;
    final targetFields = _getFields(targetType);

    buffer.writeln(
        '  @override ${targetType.getDisplayString()} ${method.name}(${sourceParam.type.getDisplayString()} ${sourceParam.name}) {');

    final constructorParams = <String>[];

    for (final targetField in targetFields) {
      if (_hasIgnoreAnnotation(targetField)) continue;

      // بررسی CustomMapping
      final customExpr = _getCustomMappingAnnotation(targetField);
      if (customExpr != null) {
        constructorParams
            .add('${targetField.name}: ${customExpr.replaceAll('value', sourceParam.name ?? '-')}');
        continue;
      }

      // بررسی Mapping روی source fields
      final mappedSourceField = sourceFields.firstWhereOrNull((f) {
        final mapping = _mappingChecker.firstAnnotationOfExact(f);
        if (mapping == null) return false;
        final targetName =
            ConstantReader(mapping).read('target').stringValue;
        return targetName == targetField.name;
      });

      String value;
      if (mappedSourceField != null) {
        value = _castIfNeeded(
            '${sourceParam.name}.${mappedSourceField.name}',
            mappedSourceField.type,
            targetField.type);
      } else {
        // fallback: فیلد هم‌نام
        final sameNameField =
        sourceFields.firstWhereOrNull((f) => f.name == targetField.name);
        value = sameNameField != null
            ? _castIfNeeded(
            '${sourceParam.name}.${sameNameField.name}',
            sameNameField.type,
            targetField.type)
            : 'null';
      }

      constructorParams.add('${targetField.name}: $value');
    }

    buffer.writeln(
        '    return ${targetType.getDisplayString()}(${constructorParams.join(', ')});');
    buffer.writeln('  }');
  }

  bool _hasIgnoreAnnotation(FieldElement field) {
    for (final annotation in _ignoreChecker.annotationsOf(field)) {
      final reader = ConstantReader(annotation);
      final peek = reader.peek('target');
      if (peek == null || peek.stringValue == field.name) return true;
    }
    return false;
  }

  String? _getCustomMappingAnnotation(FieldElement field) {
    for (final annotation in _customChecker.annotationsOf(field)) {
      final reader = ConstantReader(annotation);
      final peek = reader.peek('target')?.stringValue;
      final expr = reader.read('expression').stringValue;
      if (peek == null || peek == field.name) return expr;
    }
    return null;
  }

  String _castIfNeeded(
      String sourceExpr, DartType sourceType, DartType targetType) {
    final src = sourceType.getDisplayString();
    final tgt = targetType.getDisplayString();

    final isSourceNullable = sourceType.nullabilitySuffix != NullabilitySuffix.none;
    final isTargetNullable = targetType.nullabilitySuffix != NullabilitySuffix.none;

    if (src == tgt) return sourceExpr;

    // String -> int
    if (src == 'String' && tgt == 'int') {
      return isTargetNullable
          ? '$sourceExpr != null ? int.tryParse($sourceExpr!) : null'
          : 'int.parse($sourceExpr)';
    }

    // String -> double
    if (src == 'String' && tgt == 'double') {
      return isTargetNullable
          ? '$sourceExpr != null ? double.tryParse($sourceExpr!) : null'
          : 'double.parse($sourceExpr)';
    }

    // int/double -> String
    if ((src == 'int' || src == 'double') && tgt == 'String') {
      return isSourceNullable ? '$sourceExpr?.toString()' : '$sourceExpr.toString()';
    }

    // bool -> String
    if (src == 'bool' && tgt == 'String') {
      return isSourceNullable ? '$sourceExpr?.toString()' : '$sourceExpr.toString()';
    }

    // String -> bool
    if (src == 'String' && tgt == 'bool') {
      return isSourceNullable
          ? '$sourceExpr != null ? $sourceExpr == "true" : null'
          : '$sourceExpr == "true"';
    }

    // fallback ساده
    return '$sourceExpr as ${targetType.getDisplayString()}';
  }

  List<FieldElement> _getFields(DartType type) {
    if (type is! InterfaceType) return [];
    final element = type.element;
    if (element is! ClassElement) return [];
    return element.fields.where((f) => !f.isStatic && f.isPublic).toList();
  }

  Iterable<MethodElement> _getAllAbstractMethods(ClassElement clazz) sync* {
    yield* clazz.methods.where((m) => m.isAbstract);
    final supertype = clazz.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      yield* _getAllAbstractMethods(supertype.element as ClassElement);
    }
  }
}
