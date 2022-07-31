// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

class OpCode {
  static const Constant = 0;
  static const Print = 1;
  static const Return = 3;
}

enum Op {
  Constant(OpCode.Constant),
  Print(OpCode.Print),
  Return(OpCode.Return);

  const Op(this.code);

  final int code;
}

class CodeBuilder {
  final _code = BytesBuilder();
  final _constants = <Object?>[];

  void write(int byte) {
    assert(byte >= 0 && byte <= 255);
    _code.addByte(byte);
  }

  void writeOp(Op op) {
    write(op.index);
  }

  int addConstant(Object? value) {
    final id = _constants.length;
    _constants.add(value);
    return id;
  }

  Code build() {
    final code = _code.takeBytes();
    final constants = List.of(_constants);
    _constants.clear();
    return Code(code: code, constants: constants);
  }
}

class Code {
  Code({
    required Uint8List code,
    required List<Object?> constants,
  })  : code = UnmodifiableUint8ListView(code),
        constants = List.unmodifiable(constants);

  final Uint8List code;
  final List<Object?> constants;
}
