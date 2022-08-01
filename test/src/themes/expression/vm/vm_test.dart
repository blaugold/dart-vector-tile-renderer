import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/compiler.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/parser.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/resolver.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/vm.dart';

final parser = ExprParser();
final resolver = ExprResolver();
final compiler = ExprCompiler();

void main() {
  group('operator', () {
    test('!', () {
      evaluateConstant(['!', true], const OkResult(false));
      evaluateConstant(['!', false], const OkResult(true));
    });
  });
}

void evaluateConstant(Object? json, Object? result) {
  final expr = parser.parse(json);
  expect(parser.errors, isEmpty);

  resolver.resolve(expr);
  expect(resolver.errors, isEmpty);
  expect(expr.hasConstantResult, isTrue);
  expect(expr.constantResult, result);
}
