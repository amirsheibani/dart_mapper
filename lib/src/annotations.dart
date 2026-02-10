/// Annotation برای مشخص کردن یک Mapper
class Mapper {
  /// نام کلاس پیاده‌سازی، اگر null باشد نام پیش‌فرض استفاده می‌شود
  final String? implementationName;

  const Mapper({this.implementationName});
}

/// Annotation برای mapping بین فیلدها
/// اگر target مشخص شود، مقدار فیلد منبع با همان نام target گرفته می‌شود
class Mapping {
  final String? target;

  const Mapping({this.target});
}

/// Annotation برای نادیده گرفتن یک فیلد
class Ignore {
  final String? target;

  const Ignore({this.target});
}

/// Annotation برای mapping سفارشی با یک expression
class CustomMapping {
  final String expression;
  final String? target;

  const CustomMapping({required this.target, required this.expression});
}
