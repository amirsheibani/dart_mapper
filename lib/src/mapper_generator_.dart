// import 'package:analyzer/dart/element/element.dart';
// import 'package:analyzer/dart/element/type.dart';
// import 'package:build/build.dart';
// import 'package:source_gen/source_gen.dart';
// import 'package:collection/collection.dart';
// import 'annotations.dart';
//
// class MapperGenerator extends GeneratorForAnnotation<Mapper> {
//   final _mappingChecker = TypeChecker.fromUrl('package:dart_mapper/src/annotations.dart#Mapping');
//   final _ignoreChecker = TypeChecker.fromUrl('package:dart_mapper/src/annotations.dart#Ignore');
//   final _customChecker = TypeChecker.fromUrl('package:dart_mapper/src/annotations.dart#CustomMapping');
//
//   @override
//   String generateForAnnotatedElement(covariant Element element, ConstantReader annotation, BuildStep buildStep) {
//     if (element is! ClassElement) {
//       throw InvalidGenerationSourceError('@Mapper can only be used on classes', element: element);
//     }
//     if (!element.isAbstract) {
//       throw InvalidGenerationSourceError('@Mapper class must be abstract', element: element);
//     }
//
//     final className = element.name;
//     final implName = '${className}Impl';
//     final buffer = StringBuffer();
//     buffer.writeln('class $implName extends $className {');
//
//     final methods = _getAllAbstractMethods(element).toList();
//
//     for (final method in methods) {
//       _generateMethod(buffer, method);
//     }
//
//     buffer.writeln('}');
//     return buffer.toString();
//   }
//
//   void _generateMethod(StringBuffer buffer, MethodElement method) {
//     final params = method.formalParameters;
//     if (params.length != 1) {
//       throw InvalidGenerationSourceError('Mapper methods must have exactly one parameter', element: method);
//     }
//
//     final sourceParam = params.first;
//     final sourceType = sourceParam.type;
//     final targetType = method.returnType;
//
//     buffer.writeln('  @override');
//     buffer.writeln('  ${targetType.getDisplayString(withNullability: true)} ${method.name}(${sourceType.getDisplayString(withNullability: true)} ${sourceParam.name}) {');
//
//     buffer.writeln('    return ${targetType.getDisplayString(withNullability: false)}(');
//
//     final targetParams = _getConstructorParams(targetType);
//     final sourceFields = _getFields(sourceType);
//
//     for (final param in targetParams) {
//       final targetName = _getTargetParamName(param);
//
//       final ignore = _hasIgnoreAnnotation(method, targetName);
//       if (ignore) continue;
//
//       final custom = _getCustomMappingAnnotation(method, targetName);
//       String value;
//
//       if (custom != null) {
//         value = custom;
//       } else {
//         // mapping annotation
//         final mapping = _getMappingAnnotation(method, targetName);
//         FieldElement? field;
//         if (mapping != null) {
//           field = sourceFields.firstWhereOrNull((f) => f.name == mapping);
//         } else {
//           field = sourceFields.firstWhereOrNull((f) => f.name == param.name);
//         }
//
//         if (field != null) {
//           value = _castIfNeeded('${sourceParam.name}.${field.name}', field.type, param.type);
//         } else {
//           value = 'null';
//         }
//       }
//
//       if (param.isNamed) {
//         buffer.writeln('      ${param.name}: $value,');
//       } else {
//         buffer.writeln('      $value,');
//       }
//     }
//
//     buffer.writeln('    );');
//     buffer.writeln('  }');
//   }
//
//   /// Cast خودکار اگر نوع source با target متفاوت بود
//   String _castIfNeeded(String sourceExpr, DartType sourceType, DartType targetType) {
//     final src = sourceType.getDisplayString(withNullability: true);
//     final tgt = targetType.getDisplayString(withNullability: true);
//
//     if (src == tgt) return sourceExpr;
//
//     final targetName = targetType.getDisplayString(withNullability: false);
//
//     // چند تبدیل رایج
//     if (targetName == 'int') return 'int.parse($sourceExpr)';
//     if (targetName == 'double') return 'double.parse($sourceExpr)';
//     if (targetName == 'String') return '$sourceExpr.toString()';
//     if (targetName == 'bool') return '$sourceExpr == true';
//
//     // fallback ساده
//     return '$sourceExpr as $targetName';
//   }
//
//   String? _getMappingAnnotation(MethodElement method, String? targetName) {
//     for (final annotation in _mappingChecker.annotationsOf(method)) {
//       final reader = ConstantReader(annotation);
//       final target = reader.read('target').stringValue;
//       final source = reader.read('source').stringValue;
//       if (target == targetName) return source;
//     }
//     return null;
//   }
//
//   bool _hasIgnoreAnnotation(MethodElement method, String? targetName) {
//     for (final annotation in _ignoreChecker.annotationsOf(method)) {
//       final reader = ConstantReader(annotation);
//       // اگر target اختیاری است
//       final peek = reader.peek('target');
//       if (peek != null) {
//         final target = peek.stringValue;
//         if (target == targetName) return true;
//       } else {
//         return true; // کل فیلد یا متد ignore شود
//       }
//     }
//     return false;
//   }
//
//   String? _getCustomMappingAnnotation(MethodElement method, String? targetName) {
//     for (final annotation in _customChecker.annotationsOf(method)) {
//       final reader = ConstantReader(annotation);
//       final peek = reader.peek('target');
//       final expr = reader.read('expression').stringValue;
//       if (peek != null) {
//         final target = peek.stringValue;
//         if (target == targetName) return expr;
//       }
//     }
//     return null;
//   }
//
//   String? _getTargetParamName(FormalParameterElement param) {
//     if (param is FieldFormalParameterElement) {
//       return param.field?.name ?? param.name;
//     }
//     return param.name;
//   }
//
//   List<FormalParameterElement> _getConstructorParams(DartType type) {
//     if (type is! InterfaceType) return [];
//     final element = type.element;
//     if (element is! ClassElement) return [];
//     final ctor = _getUnnamedConstructor(element);
//     return ctor.formalParameters;
//   }
//
//   ConstructorElement _getUnnamedConstructor(ClassElement element) {
//     final ctors = element.constructors;
//     if (ctors.isEmpty) {
//       throw InvalidGenerationSourceError('Target class must have at least one constructor', element: element);
//     }
//     for (final c in ctors) {
//       if (c.name?.isEmpty ?? false) return c;
//     }
//     return ctors.first;
//   }
//
//   List<FieldElement> _getFields(DartType type) {
//     if (type is! InterfaceType) return [];
//     final element = type.element;
//     if (element is! ClassElement) return [];
//     return element.fields.where((f) => !f.isStatic && f.isPublic).toList();
//   }
//
//   Iterable<MethodElement> _getAllAbstractMethods(ClassElement clazz) sync* {
//     yield* clazz.methods.where((m) => m.isAbstract);
//     final supertype = clazz.supertype;
//     if (supertype != null && !supertype.isDartCoreObject) {
//       yield* _getAllAbstractMethods(supertype.element as ClassElement);
//     }
//   }
// }
//
// Builder mapperBuilder(BuilderOptions options) => PartBuilder([MapperGenerator()], '.g.dart');
//
//
