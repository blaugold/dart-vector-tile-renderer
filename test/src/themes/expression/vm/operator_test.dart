import 'dart:math';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/compiler.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/parser.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/resolver.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/vm.dart';

const delta = 1.0e-14;

final parser = ExprParser();
final resolver = ExprResolver();
final compiler = ExprCompiler();

void main() {
  group('operator', () {
    group('constants', () {
      test('e', () {
        evaluateConstant(['e'], okResult(e));
      });

      test('ln2', () {
        evaluateConstant(['ln2'], okResult(ln2));
      });

      test('pi', () {
        evaluateConstant(['pi'], okResult(pi));
      });
    });

    group('boolean logic', () {
      test('!', () {
        evaluateConstant(['!', true], okResult(false));
        evaluateConstant(['!', false], okResult(true));
      });
    });

    group('arithmetic', () {
      test('min', () {
        evaluateConstant(['min', 1, 2], okResult(1));
        evaluateConstant(['min', 0, 1, 2], okResult(0));
      });

      test('max', () {
        evaluateConstant(['max', 1, 2], okResult(2));
        evaluateConstant(['max', 1, 2, 3], okResult(3));
      });

      test('+', () {
        evaluateConstant(['+', 1, 2], okResult(3));
        evaluateConstant(['+', 1, 2, 3], okResult(6));
      });

      test('-', () {
        evaluateConstant(['-', 1], okResult(-1));
        evaluateConstant(['-', 1, 2], okResult(-1));
      });

      test('*', () {
        evaluateConstant(['*', 2, 3], okResult(6));
        evaluateConstant(['*', 2, 3, 4], okResult(24));
      });

      test('/', () {
        evaluateConstant(['/', 6, 3], okResult(2));
      });

      test('%', () {
        evaluateConstant(['%', 5, 2], okResult(1));
      });

      test('^', () {
        evaluateConstant(['^', 2, 3], okResult(8));
      });

      test('abs', () {
        evaluateConstant(['abs', 1], okResult(1));
        evaluateConstant(['abs', -1], okResult(1));
      });

      test('ceil', () {
        evaluateConstant(['ceil', 1.1], okResult(2));
        evaluateConstant(['ceil', 1.9], okResult(2));
      });

      test('floor', () {
        evaluateConstant(['floor', 1.1], okResult(1));
        evaluateConstant(['floor', 1.9], okResult(1));
      });

      test('round', () {
        evaluateConstant(['round', 1.1], okResult(1));
        evaluateConstant(['round', 1.9], okResult(2));
      });

      test('sin', () {
        evaluateConstant(['sin', 0], okResult(0));
        evaluateConstant(['sin', pi / 2], okResult(1));
      });

      test('asin', () {
        evaluateConstant(['asin', 0], okResult(0));
        evaluateConstant(['asin', 1], okResult(pi / 2));
      });

      test('cos', () {
        evaluateConstant(['cos', 0], okResult(1));
        evaluateConstant(['cos', pi / 2], okResult(closeTo(0, delta)));
      });

      test('acos', () {
        evaluateConstant(['acos', 1], okResult(0));
        evaluateConstant(['acos', 0], okResult(pi / 2));
      });

      test('tan', () {
        evaluateConstant(['tan', 0], okResult(0));
        evaluateConstant(['tan', pi / 4], okResult(closeTo(1, delta)));
      });

      test('atan', () {
        evaluateConstant(['atan', 0], okResult(0));
        evaluateConstant(['atan', 1], okResult(pi / 4));
      });

      test('ln', () {
        evaluateConstant(['ln', 1], okResult(0));
        evaluateConstant(['ln', e], okResult(1));
      });

      test('log2', () {
        evaluateConstant(['log2', 1], okResult(0));
        evaluateConstant(['log2', 2], okResult(1));
      });

      test('log10', () {
        evaluateConstant(['log10', 1], okResult(0));
        evaluateConstant(['log10', 10], okResult(1));
      });
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

Matcher okResult(Object? result) =>
    const TypeMatcher<OkResult>().having((r) => r.value, 'value', result);
