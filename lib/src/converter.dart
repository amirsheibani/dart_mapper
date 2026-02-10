abstract class MapperConverter<S, T> {
  const MapperConverter();
  T? convert(S? value);
}
