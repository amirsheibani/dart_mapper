import 'package:example/string_to_int_converter.dart';

import 'user_entity.dart';
import 'user_model.dart';
import 'package:dart_mapper_clean/dart_mapper_clean.dart';

part 'user_mapper.mapper.dart';


abstract class BaseMapper <E,M>{
  E toEntity(M value);
  M toModel(E value);
}

@Mapper()
abstract class UserMapper extends BaseMapper<UserEntity, UserModel> {

  @Mapping(
    target: 'id',
    ignore: true,
  )
  @Mapping(
    target: 'age',
    source: 'name',
    converter: StringToIntConverter,
  )
  @Mapping(
    target: 'email',
    condition: 'value != null',
    expression: 'value.toUpperCase()',
  )
  @override
  UserEntity toEntity(UserModel value);
}