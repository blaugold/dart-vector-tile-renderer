import 'dart:io';

void main() {
  final file = File('lib/src/themes/expression/vm/op.dart');

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ignore_for_file: constant_identifier_names');
  buffer.writeln();
  writeOpCodeConstants(buffer);
  buffer.writeln();
  writeOpCodeEnum(buffer);
  buffer.writeln();

  file.writeAsStringSync(buffer.toString(), flush: true);

  // Format the file.
  Process.runSync('dart', ['format', file.path], runInShell: true);
}

class OpCodeGroup {
  OpCodeGroup(this.name, this.opCodes);

  final String name;
  final List<String> opCodes;
}

final opCodeGroups = [
  OpCodeGroup('Constants', [
    'LoadNull',
    'LoadTrue',
    'LoadFalse',
    'LoadNumber',
    'LoadObject',
    'E',
    'Ln2',
    'Pi',
  ]),
  OpCodeGroup('Control flow', [
    'ReturnBool',
    'ReturnNumber',
    'ReturnObject',
    'ReturnError',
    'JumpIfNoError',
    'SetErrorFlag',
  ]),
  OpCodeGroup('Type checks', [
    'LoadObjectAs',
  ]),
  OpCodeGroup('Boolean logic', [
    'Not',
  ]),
  OpCodeGroup('Arithmetic', [
    'Min',
    'Max',
    'Add',
    'Subtract',
    'Multiply',
    'Divide',
    'Modulo',
    'Pow',
    'Sqrt',
    'Abs',
    'Ceil',
    'Floor',
    'Round',
    'Sin',
    'Asin',
    'Cos',
    'Acos',
    'Tan',
    'Atan',
    'Log',
    'Log2',
    'Log10',
  ]),
];

void writeOpCodeConstants(StringBuffer buffer) {
  buffer.writeln('class OpCode {');

  var i = 0;
  for (final group in opCodeGroups) {
    buffer.writeln();
    buffer.writeln('  // ${group.name}');
    for (final opCode in group.opCodes) {
      buffer.write('  static const ');
      buffer.write(opCode);
      buffer.write(' = ');
      buffer.write(i++);
      buffer.writeln(';');
    }
  }

  buffer.writeln('}');
}

void writeOpCodeEnum(StringBuffer buffer) {
  buffer.writeln('enum Op {');

  final totalOps = opCodeGroups.fold<int>(
    0,
    (previousValue, element) => previousValue + element.opCodes.length,
  );

  var i = 0;
  for (final group in opCodeGroups) {
    buffer.writeln();
    buffer.writeln('  // ${group.name}');
    for (var opCode in group.opCodes) {
      buffer.write('  ');
      buffer.write(opCode);
      buffer.write('(OpCode.');
      buffer.write(opCode);
      buffer.writeln(')');
      if (i < totalOps - 1) {
        buffer.write(',');
      } else {
        buffer.write(';');
      }
      i++;
    }
  }

  buffer.writeln();
  buffer.writeln('  const Op(this.code);');
  buffer.writeln();
  buffer.writeln('  final int code;');
  buffer.writeln('}');
}
