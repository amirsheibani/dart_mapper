

import 'package:example/user_mapper.dart';
import 'package:example/user_model.dart';

void main(List<String> arguments) {
  final userModel = UserModel(name: 'Amir', age: 30,id: '1',email: '', createdAt: null);
  final userMapper = UserMapperImpl();
  final userEntity = userMapper.toEntity(userModel);
  print(userEntity.name);
}
