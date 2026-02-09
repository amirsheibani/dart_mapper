## Dart Mapper

Elegant code generator for mapping between Dart model classes using simple `@Mapper`-style annotations.

Built on top of `source_gen` and `build_runner`, it generates type-safe mapper implementations
for your abstract mapper classes, so you don’t have to write boilerplate mapping code by hand.

---

### ✨ Features

- **Annotation-based mapping** with `@Mapper` برای تعریف Mapperهای انتزاعی
- **Field remapping** با `@Mapping(target, source)` برای مپ‌کردن فیلدهایی با نام متفاوت
- **Ignore fields** با `@Ignore` برای حذف فیلدها از مپ
- **Custom expressions** با `@CustomMapping` برای کنترل کامل روی مقداردهی فیلدها

---

### 🚀 Getting started

در `pubspec.yaml` پروژه خود اضافه کنید:

```yaml
dependencies:
  dart_mapper: ^0.1.0

dev_dependencies:
  build_runner: ^2.11.0
```

سپس جنریتور را اجرا کنید:

```bash
dart run build_runner build
```

---

### 📦 Usage

یک مدل، یک entity و یک mapper تعریف کنید:

```dart
import 'package:dart_mapper/dart_mapper.dart';

part 'user_mapper.g.dart';

class UserModel {
  final String id;
  final String name;
  final int age;

  UserModel({required this.id, required this.name, required this.age});
}

class UserEntity {
  final String? id;
  final String name;

  UserEntity({this.id, required this.name});
}

@Mapper()
abstract class UserMapper {
  @Ignore(target: 'id')
  @Mapping(target: 'name', source: 'age')
  UserEntity toEntity(UserModel value);

  UserModel toModel(UserEntity value);
}
```

بعد از اجرای `build_runner`، یک پیاده‌سازی (برای مثال `UserMapperImpl`) تولید می‌شود
که می‌توانید مستقیماً از آن استفاده کنید:

```dart
final mapper = UserMapperImpl();
final entity = mapper.toEntity(userModel);
```

---

### 📁 Example

یک مثال کامل و قابل اجرا در پوشه `example/` قرار دارد که می‌توانید آن را بررسی یا اجرا کنید.

---

### 📫 Support & Feedback

اگر باگ یا پیشنهادی دارید، لطفاً در issue tracker ریپوی پکیج ثبت کنید. مشارکت‌ها (PRها) هم خوشحال‌مان می‌کند.
