import 'package:dart_mapper_clean/dart_mapper_clean.dart';

class UserModel {
  @Ignore()
  final String? id;
  @Mapping(target: 'age')
  final String? name;
  final String? email;
  final int? age;
  final DateTime? createdAt;

  const UserModel({
     this.id,
     this.name,
     this.email,
     this.age,
     this.createdAt,
  });
}