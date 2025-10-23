abstract class Heuristic {
  Future<bool> testHeuristic();
  Future<bool> get value async => await testHeuristic();
}