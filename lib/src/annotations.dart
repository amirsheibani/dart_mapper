class Mapper {
  final String? implementationName;

  const Mapper({this.implementationName});
}

//@Mapping(target: 'name', source: 'age')
class Mapping {
  final String source;
  final String target;

  const Mapping({required this.source, required this.target});
}

//@Ignore(target: 'id')
class Ignore {
  final String? target;

  const Ignore({this.target});
}

//@CustomMapping(target: 'email', expression: 'value.email.toUpperCase()')
class CustomMapping {
  final String expression;
  final String? target;

  const CustomMapping({required this.target ,required this.expression});
}