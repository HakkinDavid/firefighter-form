abstract class Heuristic {
  Future<bool> evaluate();
  Future<bool> get result async => await evaluate();
}