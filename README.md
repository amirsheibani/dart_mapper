## Dart Mapper

Elegant code generator for mapping between Dart model classes using simple `@Mapper`-style annotations.  
ژنراتور شیک برای مپ‌کردن کلاس‌های مدل Dart با استفاده از انوتیشن ساده‌ی `@Mapper`.

Built on top of `source_gen` and `build_runner`, it generates type-safe mapper implementations
for your abstract mapper classes, so you don’t have to write boilerplate mapping code by hand.  
روی `source_gen` و `build_runner` ساخته شده و برای `abstract class`‌های شما، پیاده‌سازی‌های type-safe تولید می‌کند تا از شر کدهای تکراری مپ راحت شوید.

---

### ✨ Features / قابلیت‌ها

- **Annotation-based mapping** with `@Mapper` to define abstract mappers  
  مپ‌کردن بر اساس انوتیشن با `@Mapper` برای تعریف mapperهای انتزاعی
- **Field remapping** with `@Mapping(target, source)` for differently named fields  
  مپ‌کردن فیلدهایی که نام متفاوت دارند با `@Mapping(target, source)`
- **Ignore fields** with `@Ignore` to skip certain targets  
  نادیده‌گرفتن بعضی فیلدها در مپ با `@Ignore`
- **Custom expressions** with `@CustomMapping` for full control over values  
  استفاده از expressionهای دلخواه برای مقداردهی فیلدها با `@CustomMapping`

---

### 🚀 Getting started / شروع سریع

Add this package to your project `pubspec.yaml`:  
این پکیج را به `pubspec.yaml` پروژه خود اضافه کنید:

```yaml
dependencies:
  dart_mapper: ^0.1.0

dev_dependencies:
  build_runner: ^2.11.0
```

Then run the generator:  
بعد جنریتور را اجرا کنید:

```bash
dart run build_runner build
```

---

### 📦 Usage / نحوه استفاده

Define a model, an entity and a mapper:  
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

After running `build_runner`, an implementation (for example `UserMapperImpl`) will be generated
that you can use directly:  
بعد از اجرای `build_runner`، یک پیاده‌سازی (مثلاً `UserMapperImpl`) تولید می‌شود
که می‌توانید مستقیماً از آن استفاده کنید:

```dart
final mapper = UserMapperImpl();
final entity = mapper.toEntity(userModel);
```

---

### 📁 Example / مثال

A complete, runnable example lives in the `example/` directory.  
یک مثال کامل و قابل اجرا در پوشه `example/` قرار دارد که می‌توانید آن را بررسی یا اجرا کنید.

---

### 📫 Support & Feedback / پشتیبانی و فیدبک

If you find a bug or have a feature request, please open an issue in the repository issue tracker.  
اگر باگ یا پیشنهادی دارید، لطفاً در issue tracker ریپوی پکیج ثبت کنید؛ مشارکت‌ها (PRها) هم بسیار استقبال می‌شوند.
