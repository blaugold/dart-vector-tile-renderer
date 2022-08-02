// ignore_for_file: non_constant_identifier_names

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
  ExprResult? _result;

  @override
  ExprResult run(Code code) {
    if (debugExprVMTraceExecution) {
      // ignore: avoid_print
      print('=== Execution Start ===');
    }

    final result = _run(code);

    if (debugExprVMTraceExecution) {
      // ignore: avoid_print
      print('=== Execution End   ===');
    }

    return result;
  }

  ExprResult _run(Code code) {
    _code = ByteData.sublistView(code.code);
    _objectConstants = code.objectConstants;
    _stackObjects.clear();
    _sp = 0;
    _ip = 0;
    _errorFlag = false;
    _result = null;

    while (_result == null) {
      if (debugExprVMTraceExecution) {
        // ignore: avoid_print
        print(code.disassembleInstruction(_ip, _code));
      }

      final op = _loadOp();
      switch (op) {
        case OpCode.LoadNull:
          _LoadNull();
          break;
        case OpCode.LoadTrue:
          _LoadTrue();
          break;
        case OpCode.LoadFalse:
          _LoadFalse();
          break;
        case OpCode.LoadNumber:
          _LoadNumber();
          break;
        case OpCode.LoadObject:
          _LoadObject();
          break;
        case OpCode.E:
          _E();
          break;
        case OpCode.Ln2:
          _Ln2();
          break;
        case OpCode.Pi:
          _Pi();
          break;
        case OpCode.ReturnBool:
          _ReturnBool();
          break;
        case OpCode.ReturnNumber:
          _ReturnNumber();
          break;
        case OpCode.ReturnObject:
          _ReturnObject();
          break;
        case OpCode.ReturnError:
          _ReturnError();
          break;
        case OpCode.JumpIfNoError:
          _JumpIfNoError();
          break;
        case OpCode.SetErrorFlag:
          _SetErrorFlag();
          break;
        case OpCode.LoadObjectAs:
          _LoadObjectAs();
          break;
        case OpCode.Not:
          _Not();
          break;
        case OpCode.Min:
          _Min();
          break;
        case OpCode.Max:
          _Max();
          break;
        case OpCode.Add:
          _Add();
          break;
        case OpCode.Subtract:
          _Subtract();
          break;
        case OpCode.Multiply:
          _Multiply();
          break;
        case OpCode.Divide:
          _Divide();
          break;
        case OpCode.Modulo:
          _Modulo();
          break;
        case OpCode.Pow:
          _Pow();
          break;
        case OpCode.Sqrt:
          _Sqrt();
          break;
        case OpCode.Negate:
          _Negate();
          break;
        case OpCode.Abs:
          _Abs();
          break;
        case OpCode.Floor:
          _Floor();
          break;
        case OpCode.Ceil:
          _Ceil();
          break;
        case OpCode.Round:
          _Round();
          break;
        case OpCode.Sin:
          _Sin();
          break;
        case OpCode.Asin:
          _Asin();
          break;
        case OpCode.Cos:
          _Cos();
          break;
        case OpCode.Acos:
          _Acos();
          break;
        case OpCode.Tan:
          _Tan();
          break;
        case OpCode.Atan:
          _Atan();
          break;
        case OpCode.Log:
          _Log();
          break;
        case OpCode.Log2:
          _Log2();
          break;
        case OpCode.Log10:
          _Log10();
          break;
        default:
          _result = ErrorResult('Unknown op: $op');
          break;
      }
    }

    return _result!;
  }

  @pragma('vm:prefer-inline')
  int _loadOp() => _loadUint8();

  @pragma('vm:prefer-inline')
  int _loadUint8() => _code.getUint8(_ip++);

  @pragma('vm:prefer-inline')
  int _loadUint16() {
    final value = _code.getUint16(_ip, Endian.host);
    _ip += Uint16List.bytesPerElement;
    return value;
  }

  @pragma('vm:prefer-inline')
  int _loadUint32() {
    final value = _code.getUint32(_ip, Endian.host);
    _ip += Uint32List.bytesPerElement;
    return value;
  }

  @pragma('vm:prefer-inline')
  double _loadFloat64() {
    final value = _code.getFloat64(_ip, Endian.host);
    _ip += Float64List.bytesPerElement;
    return value;
  }

  @pragma('vm:prefer-inline')
  void _pushBool(bool value) => _stack[_sp++] = value ? 1.0 : 0.0;

  @pragma('vm:prefer-inline')
  bool _popBool() => _stack[--_sp] != 0.0;

  @pragma('vm:prefer-inline')
  void _pushNumber(double value) => _stack[_sp++] = value;

  @pragma('vm:prefer-inline')
  double _popNumber() => _stack[--_sp];

  @pragma('vm:prefer-inline')
  void _pushObject(Object? value) {
    _stackObjects.add(value);
    final objectId = _stackObjects.length - 1;
    _stack[_sp++] = objectId.toDouble();
  }

  @pragma('vm:prefer-inline')
  Object? _popObject() {
    final objectId = _stack[--_sp].toInt();
    return _stackObjects.removeAt(objectId);
  }

  @pragma('vm:prefer-inline')
  void _unaryMathOp(double Function(double x) op) {
    final sp = _sp - 1;
    _stack[sp] = op(_stack[sp]);
  }

  @pragma('vm:prefer-inline')
  void _binaryMathOp(double Function(double a, double b) op) {
    final spB = _sp - 1;
    final spA = spB - 1;
    final b = _stack[spB];
    final a = _stack[spA];
    _stack[spA] = op(a, b);
    _sp = spB;
  }

  // === Ops ===================================================================

  @pragma('vm:prefer-inline')
  void _LoadNull() => _pushObject(null);

  @pragma('vm:prefer-inline')
  void _LoadTrue() => _pushObject(true);

  @pragma('vm:prefer-inline')
  void _LoadFalse() => _pushObject(false);

  @pragma('vm:prefer-inline')
  void _LoadNumber() => _pushNumber(_loadFloat64());

  @pragma('vm:prefer-inline')
  void _LoadObject() {
    final constantId = _loadUint8();
    _pushObject(_objectConstants[constantId]);
  }

  @pragma('vm:prefer-inline')
  void _E() => _pushNumber(e);

  @pragma('vm:prefer-inline')
  void _Ln2() => _pushNumber(ln2);

  @pragma('vm:prefer-inline')
  void _Pi() => _pushNumber(pi);

  @pragma('vm:prefer-inline')
  void _ReturnBool() => _result = OkResult(_popBool());

  @pragma('vm:prefer-inline')
  void _ReturnNumber() => _result = OkResult(_popNumber());

  @pragma('vm:prefer-inline')
  void _ReturnObject() => _result = OkResult(_popObject());

  @pragma('vm:prefer-inline')
  void _ReturnError() =>
      _result = const ErrorResult('Expression evaluation failed.');

  @pragma('vm:prefer-inline')
  void _JumpIfNoError() {
    if (!_errorFlag) {
      _ip = _loadUint16();
    } else {
      _errorFlag = false;
      _ip += Uint16List.bytesPerElement;
    }
  }

  @pragma('vm:prefer-inline')
  void _SetErrorFlag() => _errorFlag = true;

  @pragma('vm:prefer-inline')
  void _LoadObjectAs() {
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

  @pragma('vm:prefer-inline')
  void _Not() => _unaryMathOp(_not);

  @pragma('vm:prefer-inline')
  void _Min() => _binaryMathOp(min);

  @pragma('vm:prefer-inline')
  void _Max() => _binaryMathOp(max);

  @pragma('vm:prefer-inline')
  void _Add() => _binaryMathOp(_add);

  @pragma('vm:prefer-inline')
  void _Subtract() => _binaryMathOp(_subtract);

  @pragma('vm:prefer-inline')
  void _Multiply() => _binaryMathOp(_multiply);

  @pragma('vm:prefer-inline')
  void _Divide() => _binaryMathOp(_divide);

  @pragma('vm:prefer-inline')
  void _Modulo() => _binaryMathOp(_modulo);

  @pragma('vm:prefer-inline')
  void _Pow() => _binaryMathOp(_pow);

  @pragma('vm:prefer-inline')
  void _Sqrt() => _unaryMathOp(sqrt);

  @pragma('vm:prefer-inline')
  void _Negate() => _unaryMathOp(_negate);

  @pragma('vm:prefer-inline')
  void _Abs() => _unaryMathOp(_abs);

  @pragma('vm:prefer-inline')
  void _Floor() => _unaryMathOp(_floor);

  @pragma('vm:prefer-inline')
  void _Ceil() => _unaryMathOp(_ceil);

  @pragma('vm:prefer-inline')
  void _Round() => _unaryMathOp(_round);

  @pragma('vm:prefer-inline')
  void _Sin() => _unaryMathOp(sin);

  @pragma('vm:prefer-inline')
  void _Asin() => _unaryMathOp(asin);

  @pragma('vm:prefer-inline')
  void _Cos() => _unaryMathOp(cos);

  @pragma('vm:prefer-inline')
  void _Acos() => _unaryMathOp(acos);

  @pragma('vm:prefer-inline')
  void _Tan() => _unaryMathOp(tan);

  @pragma('vm:prefer-inline')
  void _Atan() => _unaryMathOp(atan);

  @pragma('vm:prefer-inline')
  void _Log() => _unaryMathOp(log);

  @pragma('vm:prefer-inline')
  void _Log2() => _unaryMathOp(_log2);

  @pragma('vm:prefer-inline')
  void _Log10() => _unaryMathOp(_log10);
}

@pragma('vm:prefer-inline')
double _not(double x) => x == 0 ? 1 : 0;

@pragma('vm:prefer-inline')
double _add(double a, double b) => a + b;

@pragma('vm:prefer-inline')
double _subtract(double a, double b) => a - b;

@pragma('vm:prefer-inline')
double _multiply(double a, double b) => a * b;

@pragma('vm:prefer-inline')
double _divide(double a, double b) => a / b;

@pragma('vm:prefer-inline')
double _modulo(double a, double b) => a % b;

@pragma('vm:prefer-inline')
double _pow(double a, double b) => pow(a, b) as double;

@pragma('vm:prefer-inline')
double _negate(double x) => -x;

@pragma('vm:prefer-inline')
double _abs(double x) => x.abs();

@pragma('vm:prefer-inline')
double _floor(double x) => x.floorToDouble();

@pragma('vm:prefer-inline')
double _ceil(double x) => x.ceilToDouble();

@pragma('vm:prefer-inline')
double _round(double x) => x.roundToDouble();

@pragma('vm:prefer-inline')
double _log2(double x) => log(x) / ln2;

@pragma('vm:prefer-inline')
double _log10(double x) => log(x) / ln10;
