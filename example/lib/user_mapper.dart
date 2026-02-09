import 'user_entity.dart';
import 'user_model.dart';
import 'package:dart_mapper_clean/dart_mapper_clean.dart';

part 'user_mapper.g.dart';

@Mapper()
abstract class UserMapper {
  @Ignore(target: 'id')
  @Mapping(target: 'name',source: 'age')
  UserEntity toEntity(UserModel value);

  UserModel toModel(UserEntity value);
}