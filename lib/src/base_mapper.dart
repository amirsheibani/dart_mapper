abstract class BaseMapper <E,M>{
  E toEntity(M value);
  M toModel(E value);
}