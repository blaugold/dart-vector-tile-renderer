import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_tile_renderer/src/themes/expression/caching_expression.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class TreeWalkerBenchmark extends BenchmarkBase {
  TreeWalkerBenchmark(String name, this.expr) : super('TreeWalker: $name');

  final Object? expr;

  final _context = EvaluationContext(
    () => {},
    TileFeatureType.background,
    const Logger.noop(),
    zoom: 0,
    zoomScaleFactor: 0,
  );

  late final Expression expression;

  @override
  void setup() {
    enableExpressionConstantEvaluation = false;
    enableExpressionCaching = false;
    expression = ExpressionParser(const Logger.console()).parse(expr);
    enableExpressionConstantEvaluation = true;
    enableExpressionCaching = true;

    final result = expression.evaluate(_context);
    if (result == null) {
      throw 'Evaluation error';
    } else {
      // ignore: avoid_print
      print(result);
    }
  }

  @override
  void run() {
    for (var i = 0; i < 10; i++) {
      expression.evaluate(_context);
    }
  }
}
