import 'dart:typed_data';

import 'code.dart';

abstract class VM {
  factory VM() = _VM;

  void run(Code code);
}

abstract class VMResult {
  const VMResult();
}

class OkResult extends VMResult {
  final Object? result;

  const OkResult(this.result);
}

class ErrorResult extends VMResult implements Exception {
  const ErrorResult(this.message);

  final String message;

  @override
  String toString() => 'VM Error: $message';
}

class _VM implements VM {
  var _code = Uint8List(0);
  var _constants = <Object?>[];
  final _stack = <Object?>[];
  var _pc = 0;

  @override
  VMResult run(Code code) {
    _code = code.code;
    _constants = code.constants;
    _stack.clear();
    _pc = 0;

    while (true) {
      final op = _loadCodeByte();
      switch (op) {
        case OpCode.Constant:
          _loadConstant();
          break;
        case OpCode.Print:
          _print();
          break;
        case OpCode.Return:
          return OkResult(_pop());
        default:
          return ErrorResult('Unknown op: $op');
      }
    }
  }

  int _loadCodeByte() => _code[_pc++];

  void _push(Object? value) => _stack.add(value);

  Object? _pop() => _stack.removeLast();

  void _loadConstant() {
    final id = _loadCodeByte();
    _push(_constants[id]);
  }

  void _print() {
    // ignore: avoid_print
    print(_pop());
  }
}
