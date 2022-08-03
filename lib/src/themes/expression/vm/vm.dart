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

typedef _Stack = _StackValue;

class _StackValue {
  _StackValue();

  factory _StackValue.createStack(int size) {
    var i = 0;
    var stack = _StackValue();

    while (i < size) {
      final value = _StackValue();
      stack.previous = value;
      value.next = stack;
      stack = value;
      i++;
    }

    return stack;
  }

  double value = 0;
  Object? object;
  _StackValue? next;
  _StackValue? previous;

  void reset() {
    var value = this;
    while (true) {
      value.value = 0;
      value.object = null;
      final next = value.next;
      if (next == null) {
        break;
      }
      value = next;
    }
  }

  @pragma('vm:prefer-inline')
  _StackValue get(int offset) {
    var stack = this;
    while (offset > 0) {
      final previous = stack.previous;
      if (previous == null) {
        throw Exception('Stack underflow.');
      }
      stack = previous;
      offset--;
    }
    return stack;
  }

  @pragma('vm:prefer-inline')
  _StackValue push(double value) {
    var next = this.next;
    if (next == null) {
      next = _StackValue();
      next.previous = this;
      this.next = next;
    }
    next.value = value;
    return next;
  }

  @pragma('vm:prefer-inline')
  _StackValue pushObject(Object? object) {
    var next = this.next;
    if (next == null) {
      next = _StackValue();
      next.previous = this;
      this.next = next;
    }
    next.object = object;
    return next;
  }

  @pragma('vm:prefer-inline')
  _StackValue pop() {
    final previous = this.previous;
    if (previous == null) {
      throw Exception('Stack underflow.');
    }
    return previous;
  }

  @pragma('vm:prefer-inline')
  _StackValue popObject() {
    final previous = this.previous;
    if (previous == null) {
      throw Exception('Stack underflow.');
    }
    previous.object = null;
    return previous;
  }
}

class _ExprVM implements ExprVM {
  static const _initialStackSize = 256;
  static final _stack = _StackValue.createStack(_initialStackSize);

  @override
  ExprResult run(Code code) {
    if (debugExprVMTraceExecution) {
      // ignore: avoid_print
      print('=== Execution Start ===');
    }

    try {
      final result = _run(code);

      if (debugExprVMTraceExecution) {
        // ignore: avoid_print
        print('=== Execution End   ===');
      }

      return result;
    } catch (e) {
      _stack.reset();
      rethrow;
    }
  }

  ExprResult _run(Code code) {
    final instructions = ByteData.sublistView(code.code);
    final objectConstants = code.objectConstants;
    var stack = _stack;
    var ip = 0;
    var errorFlag = false;

    while (ip < instructions.lengthInBytes) {
      if (debugExprVMTraceExecution) {
        // ignore: avoid_print
        print(code.disassembleInstruction(ip, instructions));
      }

      final op = _readOp(instructions, ip);
      ip = _consumeOp(ip);
      switch (op) {
        case OpCode.LoadNull:
          stack = stack.pushObject(null);
          break;
        case OpCode.LoadTrue:
          stack = stack.push(1);
          break;
        case OpCode.LoadFalse:
          stack = stack.push(0);
          break;
        case OpCode.LoadNumber:
          final value = _readNumber(instructions, ip);
          ip = _consumeNumber(ip);
          stack = stack.push(value);
          break;
        case OpCode.LoadObject:
          final objectId = _readObjectId(instructions, ip);
          ip = _consumeObjectId(ip);
          stack = stack.pushObject(objectConstants[objectId]);
          break;
        case OpCode.E:
          stack = stack.push(e);
          break;
        case OpCode.Ln2:
          stack = stack.push(ln2);
          break;
        case OpCode.Pi:
          stack = stack.push(pi);
          break;
        case OpCode.Not:
          _unaryMathOp(stack, _not);
          break;
        case OpCode.Add:
          stack = _binaryMathOp(stack, _add);
          break;
        case OpCode.Subtract:
          stack = _binaryMathOp(stack, _subtract);
          break;
        case OpCode.Multiply:
          stack = _binaryMathOp(stack, _multiply);
          break;
        case OpCode.Divide:
          stack = _binaryMathOp(stack, _divide);
          break;
        case OpCode.Modulo:
          stack = _binaryMathOp(stack, _modulo);
          break;
        case OpCode.Pow:
          stack = _binaryMathOp(stack, _pow);
          break;
        case OpCode.Sqrt:
          _unaryMathOp(stack, sqrt);
          break;
        case OpCode.Min:
          stack = _binaryMathOp(stack, min);
          break;
        case OpCode.Max:
          stack = _binaryMathOp(stack, max);
          break;
        case OpCode.Negate:
          _unaryMathOp(stack, _negate);
          break;
        case OpCode.Abs:
          _unaryMathOp(stack, _abs);
          break;
        case OpCode.Floor:
          _unaryMathOp(stack, _floor);
          break;
        case OpCode.Ceil:
          _unaryMathOp(stack, _ceil);
          break;
        case OpCode.Round:
          _unaryMathOp(stack, _round);
          break;
        case OpCode.Sin:
          _unaryMathOp(stack, sin);
          break;
        case OpCode.Asin:
          _unaryMathOp(stack, asin);
          break;
        case OpCode.Cos:
          _unaryMathOp(stack, cos);
          break;
        case OpCode.Acos:
          _unaryMathOp(stack, acos);
          break;
        case OpCode.Tan:
          _unaryMathOp(stack, tan);
          break;
        case OpCode.Atan:
          _unaryMathOp(stack, atan);
          break;
        case OpCode.Log:
          _unaryMathOp(stack, log);
          break;
        case OpCode.Log2:
          _unaryMathOp(stack, _log2);
          break;
        case OpCode.Log10:
          _unaryMathOp(stack, _log10);
          break;
        case OpCode.LoadObjectAs:
          final stackOffset = _readStackOffset(instructions, ip);
          ip = _consumeStackOffset(ip);
          final type = _readTypedId(instructions, ip);
          ip = _consumeTypedId(ip);
          final stackValue = stack.get(stackOffset);
          final object = stackValue.object;

          var checkSucceeded = false;
          switch (type) {
            case 0: // Bool
              if (object is bool) {
                checkSucceeded = true;
                stackValue.value = object ? 1.0 : 0.0;
              }
              break;
            case 1: // Number
              if (object is double) {
                checkSucceeded = true;
                stackValue.value = object;
              }
              break;
            default:
              assert(false, 'Unknown type id: $type');
          }

          if (checkSucceeded) {
            // Consume the unused arguments.
            ip = _consumePopCount(ip);
            ip = _consumeJumpAddress(ip);
          } else {
            // Clean up the stack.
            final popCount = _readPopCount(instructions, ip);
            ip = _consumePopCount(ip);
            for (var i = 0; i < popCount; i++) {
              stack = stack.popObject();
            }

            // Jump to the error handler.
            final errorHandlerAddress = _readJumpAddress(instructions, ip);
            errorFlag = true;
            ip = errorHandlerAddress;
          }
          break;
        case OpCode.SetErrorFlag:
          errorFlag = true;
          break;
        case OpCode.JumpIfNoError:
          if (!errorFlag) {
            ip = _readJumpAddress(instructions, ip);
          } else {
            errorFlag = false;
            ip = _consumeJumpAddress(ip);
          }
          break;
        case OpCode.ReturnBool:
          final value = stack.value == 0 ? false : true;
          stack = stack.pop();
          return OkResult(value);
        case OpCode.ReturnNumber:
          final value = stack.value;
          stack = stack.pop();
          return OkResult(value);
        case OpCode.ReturnObject:
          final value = stack.object;
          stack = stack.popObject();
          return OkResult(value);
        case OpCode.ReturnError:
          return const ErrorResult('Expression evaluation failed.');
        default:
          throw StateError('Unknown opcode: $op');
      }
    }

    throw StateError('Expression did not return a value.');
  }
}

@pragma('vm:prefer-inline')
int _readUint8(ByteData instructions, int ip) => instructions.getUint8(ip);

@pragma('vm:prefer-inline')
int _consumeUint8(int ip) => ip + 1;

@pragma('vm:prefer-inline')
int _readUint16(ByteData instructions, int ip) =>
    instructions.getUint16(ip, Endian.host);

@pragma('vm:prefer-inline')
int _consumeUint16(int ip) => ip + Uint16List.bytesPerElement;

@pragma('vm:prefer-inline')
int _readUint32(ByteData instructions, int ip) =>
    instructions.getUint32(ip, Endian.host);

@pragma('vm:prefer-inline')
int _consumeUint32(int ip) => ip + Uint32List.bytesPerElement;

@pragma('vm:prefer-inline')
double _readFloat64(ByteData instructions, int ip) =>
    instructions.getFloat64(ip, Endian.host);

@pragma('vm:prefer-inline')
int _consumeFloat64(int ip) => ip + Float64List.bytesPerElement;

@pragma('vm:prefer-inline')
int _readOp(ByteData instructions, int ip) => _readUint8(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeOp(int ip) => _consumeUint8(ip);

@pragma('vm:prefer-inline')
double _readNumber(ByteData instructions, int ip) =>
    _readFloat64(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeNumber(int ip) => _consumeFloat64(ip);

@pragma('vm:prefer-inline')
int _readObjectId(ByteData instructions, int ip) =>
    _readUint8(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeObjectId(int ip) => _consumeUint8(ip);

@pragma('vm:prefer-inline')
int _readJumpAddress(ByteData instructions, int ip) =>
    _readUint16(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeJumpAddress(int ip) => _consumeUint16(ip);

@pragma('vm:prefer-inline')
int _readStackOffset(ByteData instructions, int ip) =>
    _readUint8(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeStackOffset(int ip) => _consumeUint8(ip);

@pragma('vm:prefer-inline')
int _readTypedId(ByteData instructions, int ip) => _readUint8(instructions, ip);

@pragma('vm:prefer-inline')
int _consumeTypedId(int ip) => _consumeUint8(ip);

@pragma('vm:prefer-inline')
int _readPopCount(ByteData instructions, int ip) =>
    _readUint8(instructions, ip);

@pragma('vm:prefer-inline')
int _consumePopCount(int ip) => _consumeUint8(ip);

@pragma('vm:prefer-inline')
void _unaryMathOp(_Stack stack, double Function(double x) op) {
  stack.value = op(stack.value);
}

@pragma('vm:prefer-inline')
_Stack _binaryMathOp(
  _Stack stack,
  double Function(double a, double b) op,
) {
  final b = stack.value;
  stack = stack.pop();
  final a = stack.value;
  stack.value = op(a, b);
  return stack;
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
