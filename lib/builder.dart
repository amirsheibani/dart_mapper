import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/mapper_generator.dart';

Builder mapperBuilder(BuilderOptions options) => PartBuilder([MapperGenerator()], '.mapper.dart');
