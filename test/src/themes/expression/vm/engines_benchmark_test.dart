import 'dart:developer';

import 'package:test/test.dart';

import 'tree_walker_benchmark.dart';
import 'vm_benchmark.dart';

const arithmeticExpr = [
  '+',
  ['-', 1, 2],
  ['*', 3, 4],
  ['/', 5, 6],
  ['%', 7, 8],
  ['^', 9, 10],
  ['-', 1, 2],
  ['*', 3, 4],
  ['/', 5, 6],
  ['%', 7, 8],
  ['^', 9, 10],
  ['-', 1, 2],
  ['*', 3, 4],
  ['/', 5, 6],
  ['%', 7, 8],
  ['^', 9, 10],
  ['-', 1, 2],
  ['*', 3, 4],
  ['/', 5, 6],
  ['%', 7, 8],
  ['^', 9, 10],
  [
    '+',
    ['-', 1, 2],
    ['*', 3, 4],
    ['/', 5, 6],
    ['%', 7, 8],
    ['^', 9, 10],
    ['-', 1, 2],
    ['*', 3, 4],
    ['/', 5, 6],
    ['%', 7, 8],
    ['^', 9, 10],
    ['-', 1, 2],
    ['*', 3, 4],
    ['/', 5, 6],
    ['%', 7, 8],
    ['^', 9, 10],
    ['-', 1, 2],
    ['*', 3, 4],
    ['/', 5, 6],
    ['%', 7, 8],
    ['^', 9, 10],
    [
      '+',
      ['-', 1, 2],
      ['*', 3, 4],
      ['/', 5, 6],
      ['%', 7, 8],
      ['^', 9, 10],
      ['-', 1, 2],
      ['*', 3, 4],
      ['/', 5, 6],
      ['%', 7, 8],
      ['^', 9, 10],
      ['-', 1, 2],
      ['*', 3, 4],
      ['/', 5, 6],
      ['%', 7, 8],
      ['^', 9, 10],
      ['-', 1, 2],
      ['*', 3, 4],
      ['/', 5, 6],
      ['%', 7, 8],
      ['^', 9, 10],
    ]
  ]
];

void main() {
  test('engines benchmarks', () {
    const debug = false;
    // ignore: dead_code
    if (debug) {
      debugger();
    }

    final benchmarks = [
      TreeWalkerBenchmark('Arithmetic', arithmeticExpr),
      VMBenchmark('Arithmetic', arithmeticExpr),
    ];

    for (final benchmark in benchmarks) {
      benchmark.report();
    }

    // ignore: dead_code
    if (debug) {
      debugger();
    }
  });
}
