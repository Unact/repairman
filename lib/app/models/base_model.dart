import 'dart:async';

abstract class BaseModel<T> {
  Future<T> insert();
  Future<T> update();
  Future<void> delete();
  Future<void> save();
  Map<String, dynamic> toMap();
}
