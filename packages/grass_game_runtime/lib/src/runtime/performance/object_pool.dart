class ObjectPool<T> {
  ObjectPool(this._create);

  final T Function() _create;
  final List<T> _items = [];

  T acquire() {
    if (_items.isEmpty) {
      return _create();
    }

    return _items.removeLast();
  }

  void release(T item) {
    _items.add(item);
  }
}
