class SpatialHashGrid<T> {
  SpatialHashGrid({
    required this.cellSize,
  });

  final double cellSize;
  final Map<String, List<T>> _cells = {};

  void clear() {
    _cells.clear();
  }

  void insert(String cellKey, T item) {
    _cells.putIfAbsent(cellKey, () => []).add(item);
  }

  List<T> query(String cellKey) {
    return List.unmodifiable(_cells[cellKey] ?? const []);
  }
}
