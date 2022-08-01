import 'dart:math';
import 'dart:typed_data';

import 'code.dart';
import 'debug.dart';
import 'op.dart';

abstract class ExprVM {
  factory ExprVM() = _ExprVM;

  ExprResult run(Code code);
}

abstract class ExprResult {
  const ExprResult();
}

class OkResult extends ExprResult {
  final Object? value;

  const OkResult(this.value);

  @override
  bool operator ==(Object other) =>
      identical(other, this) || other is OkResult && other.value == value;

  @override
  int get hashCode => runtimeType.hashCode ^ value.hashCode;

  @override
  String toString() => 'OkResult($value)';
}

class ErrorResult extends ExprResult implements Exception {
  const ErrorResult(this.message);
  final String message;

  @override
  String toString() => 'Expression evaluation error: $message';
}

class _ExprVM implements ExprVM {
  static const _stackSize = 8 * 1024; // 8 KB

  var _code = ByteData(0);
  var _objectConstants = <Object?>[];
  final _stack = Float64List(_stackSize ~/ Float64List.bytesPerElement);
  final _stackObjects = <Object?>[];
  var _sp = 0;
  var _ip = 0;
  var _errorFlag = false;

  @override
  ExprResult run(Code code) {
    _code = ByteData.sublistView(code.code);
    _objectConstants = code.objectConstants;

    if (debugExprVMTraceExecution) {
      // ignore: avoid_print
      print('=== Execution Start ===');
    }

    try {
      while (true) {
        if (debugExprVMTraceExecution) {
          // ignore: avoid_print
          print(code.disassembleInstruction(_ip, _code));
        }

        final op = _loadOp();
        switch (op) {
          case OpCode.LoadNull:
            _pushObject(null);
            break;
          case OpCode.LoadTrue:
            _pushBool(true);
            break;
          case OpCode.LoadFalse:
            _pushBool(false);
            break;
          case OpCode.LoadNumber:
            _loadNumber();
            break;
          case OpCode.LoadObject:
            _loadObject();
            break;
          case OpCode.E:
            _pushNumber(e);
            break;
          case OpCode.Ln2:
            _pushNumber(ln2);
            break;
          case OpCode.Pi:
            _pushNumber(pi);
            break;
          case OpCode.ReturnBool:
            return OkResult(_popBool());
          case OpCode.ReturnNumber:
            return OkResult(_popNumber());
          case OpCode.ReturnObject:
            return OkResult(_popObject());
          case OpCode.ReturnError:
            return const ErrorResult('Expression evaluation failed.');
          case OpCode.JumpIfNoError:
            _jumpIfNoError();
            break;
          case OpCode.SetErrorFlag:
            _errorFlag = true;
            break;
          case OpCode.LoadObjectAs:
            _loadObjectAs();
            break;
          case OpCode.Not:
            _unaryMathOp((x) => x == 0 ? 1 : 0);
            break;
          case OpCode.Min:
            _binaryMathOp(min);
            break;
          case OpCode.Max:
            _binaryMathOp(max);
            break;
          case OpCode.Add:
            _binaryMathOp((a, b) => a + b);
            break;
          case OpCode.Subtract:
            _binaryMathOp((a, b) => a - b);
            break;
          case OpCode.Multiply:
            _binaryMathOp((a, b) => a * b);
            break;
          case OpCode.Divide:
            _binaryMathOp((a, b) => a / b);
            break;
          case OpCode.Modulo:
            _binaryMathOp((a, b) => a % b);
            break;
          case OpCode.Pow:
            _binaryMathOp((a, b) => pow(a, b) as double);
            break;
          case OpCode.Sqrt:
            _unaryMathOp(sqrt);
            break;
          case OpCode.Abs:
            _unaryMathOp((x) => x.abs());
            break;
          case OpCode.Floor:
            _unaryMathOp((x) => x.floorToDouble());
            break;
          case OpCode.Ceil:
            _unaryMathOp((x) => x.ceilToDouble());
            break;
          case OpCode.Round:
            _unaryMathOp((x) => x.roundToDouble());
            break;
          case OpCode.Sin:
            _unaryMathOp(sin);
            break;
          case OpCode.Asin:
            _unaryMathOp(asin);
            break;
          case OpCode.Cos:
            _unaryMathOp(cos);
            break;
          case OpCode.Acos:
            _unaryMathOp(acos);
            break;
          case OpCode.Tan:
            _unaryMathOp(tan);
            break;
          case OpCode.Atan:
            _unaryMathOp(atan);
            break;
          case OpCode.Log:
            _unaryMathOp(log);
            break;
          case OpCode.Log2:
            _unaryMathOp((x) => log(x) / ln2);
            break;
          case OpCode.Log10:
            _unaryMathOp((x) => log(x) / ln10);
            break;
          default:
            return ErrorResult('Unknown op: $op');
        }
      }
    } finally {
      if (debugExprVMTraceExecution) {
        // ignore: avoid_print
        print('=== Execution End   ===');
      }

      _code = ByteData(0);
      _objectConstants = [];
      _stackObjects.clear();
      _sp = 0;
      _ip = 0;
    }
  }

  int _loadOp() => _loadUint8();

  int _loadUint8() => _code.getUint8(_ip++);

  int _loadUint16() {
    final value = _code.getUint16(_ip, Endian.host);
    _ip += Uint16List.bytesPerElement;
    return value;
  }

  double _loadFloat64() {
    final value = _code.getFloat64(_ip, Endian.host);
    _ip += Float64List.bytesPerElement;
    return value;
  }

  void _pushBool(bool value) => _stack[_sp++] = value ? 1.0 : 0.0;

  bool _popBool() => _stack[--_sp] != 0.0;

  void _pushNumber(double value) => _stack[_sp++] = value;

  double _popNumber() => _stack[--_sp];

  void _pushObject(Object? value) {
    _stackObjects.add(value);
    final objectId = _stackObjects.length - 1;
    _stack[_sp++] = objectId.toDouble();
  }

  Object? _popObject() {
    final objectId = _stack[--_sp].toInt();
    return _stackObjects.removeAt(objectId);
  }

  void _loadNumber() => _pushNumber(_loadFloat64());

  void _loadObject() {
    final constantId = _loadUint8();
    _pushObject(_objectConstants[constantId]);
  }

  void _jumpIfNoError() {
    if (!_errorFlag) {
      _ip = _loadUint16();
    } else {
      _errorFlag = false;
      _ip += Uint16List.bytesPerElement;
    }
  }

  void _loadObjectAs() {
    final offset = _loadUint8();
    final type = _loadUint8();
    final stackOffset = _sp - 1 - offset;
    final objectStackOffset = _stack[stackOffset].toInt();
    final object = _stackObjects.removeAt(objectStackOffset);

    var checkSucceeded = false;
    switch (type) {
      case 0: // Bool
        if (object is bool) {
          checkSucceeded = true;
          _stack[stackOffset] = object ? 1.0 : 0.0;
        }
        break;
      case 1: // Number
        if (object is double) {
          checkSucceeded = true;
          _stack[stackOffset] = object;
          return;
        }
        break;
      default:
        assert(false, 'Unknown type id: $type');
    }

    if (checkSucceeded) {
      // Consume the unused arguments.
      _ip += Uint8List.bytesPerElement + Uint16List.bytesPerElement;
    } else {
      // Clean up the stack.
      final encodedValuesToPop = _loadUint8();
      final valuesToPop = encodedValuesToPop >> 4;
      final objectsToPop = encodedValuesToPop & 0x0F;
      _sp -= valuesToPop;
      _stackObjects.removeRange(
        // -1 because we already removed the target object.
        _stackObjects.length - (objectsToPop - 1),
        _stackObjects.length,
      );

      // Jump to the error handler.
      final errorHandlerAddress = _loadUint16();
      _errorFlag = true;
      _ip = errorHandlerAddress;
    }
  }

  void _unaryMathOp(double Function(double x) op) {
    final offset = _sp - 1;
    _stack[offset] = op(_stack[offset]);
  }

  void _binaryMathOp(double Function(double a, double b) op) {
    final b = _popNumber();
    final a = _popNumber();
    _pushNumber(op(a, b));
  }
}
