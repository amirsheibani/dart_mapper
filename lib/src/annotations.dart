class Mapper {
  final String? implementationName;
  const Mapper({this.implementationName});
}

class Mapping {
  final String target;
  final String? source;
  final bool? ignore;
  final String? condition;
  final String? expression;
  final Type? converter;

  const Mapping({
    required this.target,
    this.source,
    this.ignore,
    this.condition,
    this.expression,
    this.converter,
  });
}
