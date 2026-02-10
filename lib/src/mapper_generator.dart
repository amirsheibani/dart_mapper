import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';

class MapperGenerator extends GeneratorForAnnotation<Mapper> {
  final _mappingChecker = TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#Mapping');

  final _ignoreChecker = TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#Ignore');

  final _customChecker = TypeChecker.fromUrl('package:dart_mapper_clean/src/annotations.dart#CustomMapping');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Mapper can only be used on classes',
        element: element,
      );
    }

    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@Mapper class must be abstract',
        element: element,
      );
    }

    final className = element.name;
    final implName = annotation.peek('implementationName')?.stringValue ?? '${className}Impl';

    final buffer = StringBuffer();
    buffer.writeln('class $implName extends $className {');

    final genericMap = _collectGenericTypes(element);

    final methods = _getAllAbstractMethods(element).toList();
    for (final method in methods) {
      _generateMethod(buffer, method, genericMap);
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Method generation
  // ---------------------------------------------------------------------------

  void _generateMethod(
    StringBuffer buffer,
    MethodElement method,
    Map<TypeParameterElement, DartType> generics,
  ) {
    final params = method.formalParameters;
    if (params.length != 1) {
      throw InvalidGenerationSourceError(
        'Mapper methods must have exactly one parameter',
        element: method,
      );
    }

    final sourceParam = params.first;
    final sourceType = _resolveType(sourceParam.type, generics);
    final targetType = _resolveType(method.returnType, generics);

    final sourceFields = _getFields(sourceType);
    final targetFields = _getFields(targetType);

    buffer.writeln(
      '  @override ${targetType.getDisplayString()} '
      '${method.name}(${sourceType.getDisplayString()} ${sourceParam.name}) {',
    );

    final constructorParams = <String>[];

    for (final targetField in targetFields) {
      if (_hasIgnoreAnnotation(targetField)) continue;

      // CustomMapping
      final customExpr = _getCustomMappingAnnotation(targetField);
      if (customExpr != null) {
        constructorParams.add(
          '${targetField.name}: '
          '${customExpr.replaceAll('value', sourceParam.name!)}',
        );
        continue;
      }

      // Mapping annotation on source
      final mappedSourceField = sourceFields.firstWhereOrNull((f) {
        final mapping = _mappingChecker.firstAnnotationOfExact(f);
        if (mapping == null) return false;
        final targetName = ConstantReader(mapping).read('target').stringValue;
        return targetName == targetField.name;
      });

      String value;
      if (mappedSourceField != null) {
        value = _castIfNeeded(
          '${sourceParam.name}.${mappedSourceField.name}',
          mappedSourceField.type,
          targetField.type,
        );
      } else {
        // fallback: same name
        final sameNameField = sourceFields.firstWhereOrNull((f) => f.name == targetField.name);

        value = sameNameField != null
            ? _castIfNeeded(
                '${sourceParam.name}.${sameNameField.name}',
                sameNameField.type,
                targetField.type,
              )
            : 'null';
      }

      constructorParams.add('${targetField.name}: $value');
    }

    buffer.writeln(
      '    return ${targetType.getDisplayString()}('
      '${constructorParams.join(', ')});',
    );
    buffer.writeln('  }');
  }

  // ---------------------------------------------------------------------------
  // Generic resolution
  // ---------------------------------------------------------------------------

  Map<TypeParameterElement, DartType> _collectGenericTypes(
    ClassElement element,
  ) {
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
  ) {
    if (type is TypeParameterType) {
      return generics[type.element] ?? type;
    }
    return type;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
      final target = reader.peek('target')?.stringValue;
      final expr = reader.read('expression').stringValue;
      if (target == null || target == field.name) return expr;
    }
    return null;
  }

  String _castIfNeeded(
    String sourceExpr,
    DartType sourceType,
    DartType targetType,
  ) {
    final src = sourceType.getDisplayString();
    final tgt = targetType.getDisplayString();

    final isSourceNullable = sourceType.nullabilitySuffix != NullabilitySuffix.none;
    final isTargetNullable = targetType.nullabilitySuffix != NullabilitySuffix.none;

    if (src == tgt) return sourceExpr;

    if (src == 'String' && tgt == 'int') {
      return isTargetNullable ? '$sourceExpr != null ? int.tryParse($sourceExpr!) : null' : 'int.parse($sourceExpr)';
    }

    if (src == 'String' && tgt == 'double') {
      return isTargetNullable ? '$sourceExpr != null ? double.tryParse($sourceExpr!) : null' : 'double.parse($sourceExpr)';
    }

    if ((src == 'int' || src == 'double') && tgt == 'String') {
      return isSourceNullable ? '$sourceExpr?.toString()' : '$sourceExpr.toString()';
    }

    if (src == 'bool' && tgt == 'String') {
      return isSourceNullable ? '$sourceExpr?.toString()' : '$sourceExpr.toString()';
    }

    if (src == 'String' && tgt == 'bool') {
      return isSourceNullable ? '$sourceExpr != null ? $sourceExpr == "true" : null' : '$sourceExpr == "true"';
    }

    return '$sourceExpr as ${targetType.getDisplayString()}';
  }

  List<FieldElement> _getFields(DartType type) {
    if (type is! InterfaceType) return const [];
    final element = type.element;
    if (element is! ClassElement) return const [];
    return element.fields.where((f) => !f.isStatic && f.isPublic).toList();
  }

  Iterable<MethodElement> _getAllAbstractMethods(
    ClassElement clazz,
  ) sync* {
    yield* clazz.methods.where((m) => m.isAbstract);
    final supertype = clazz.supertype;
    if (supertype != null && !supertype.isDartCoreObject) {
      yield* _getAllAbstractMethods(
        supertype.element as ClassElement,
      );
    }
  }
}
