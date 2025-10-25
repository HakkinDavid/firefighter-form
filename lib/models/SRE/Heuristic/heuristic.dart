abstract class Heuristic {
  Future<bool> execute();
  Future<bool> get result async => await execute();
}