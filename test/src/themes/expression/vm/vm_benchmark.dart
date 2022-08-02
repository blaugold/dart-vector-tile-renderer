import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/code.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/compiler.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/debug.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/parser.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/resolver.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/vm.dart';

class VMBenchmark extends BenchmarkBase {
  VMBenchmark(String name, this.expr) : super('VM: $name');

  final Object? expr;

  final parser = ExprParser();
  final resolver = ExprResolver(evaluateConstants: false);
  final compiler = ExprCompiler();
  final vm = ExprVM();

  late final Code code;

  @override
  void setup() {
    final ast = parser.parse(expr);
    if (parser.hadError) {
      throw 'Parser errors: ${parser.errors}';
    }

    resolver.resolve(ast);
    if (resolver.hadError) {
      throw 'Resolver errors: ${resolver.errors}';
    }

    code = compiler.compile(ast);

    final result = vm.run(code);
    if (result is! OkResult) {
      // ignore: avoid_print
      print(code.disassemble());
      throw 'Runtime error: $result';
    } else {
      // ignore: avoid_print
      print(result);
    }
  }

  @override
  void run() {
    for (var i = 0; i < 10; i++) {
      vm.run(code);
    }
  }
}
