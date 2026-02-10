import 'package:dart_mapper_clean/dart_mapper_clean.dart';


class UserEntity {
  @Ignore()
  String? id;
  String? name;
  String? email;
  @Mapping(target: 'name')
  int? age;
  DateTime? createdAt;

  UserEntity({this.id, this.name, this.email, this.age, this.createdAt});
}
