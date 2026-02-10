import 'user_entity.dart';
import 'user_model.dart';
import 'package:dart_mapper_clean/dart_mapper_clean.dart';

part 'user_mapper.mapper.dart';


abstract class BaseMapper <E,M>{
  E toEntity(M value);
  M toModel(E value);
}

@Mapper()
abstract class UserMapper extends BaseMapper<UserEntity,UserModel>{}

