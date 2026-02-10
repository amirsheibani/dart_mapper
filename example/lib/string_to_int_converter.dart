import 'package:dart_mapper_clean/dart_mapper_clean.dart';

class StringToIntConverter extends MapperConverter<String, int> {
  const StringToIntConverter();

  @override
  int? convert(String? value) => int.tryParse(value ?? '');
}