// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'user_mapper.dart';

// **************************************************************************
// MapperGenerator
// **************************************************************************

class UserMapperImpl extends UserMapper {
  @override
  UserEntity toEntity(UserModel value) {
    return UserEntity(
      name: value.name,
      email: value.email,
      age: value.name != null ? int.tryParse(value.name!) : null,
      createdAt: value.createdAt,
    );
  }

  @override
  UserModel toModel(UserEntity value) {
    return UserModel(
      name: value.age?.toString(),
      email: value.email,
      age: value.age,
      createdAt: value.createdAt,
    );
  }
}
