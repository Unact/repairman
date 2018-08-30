import 'dart:async';

abstract class BaseModel<T> {
  Future<T> insert();
  Future<T> update();
  Future<void> delete();
  Map<String, dynamic> toMap();
}
