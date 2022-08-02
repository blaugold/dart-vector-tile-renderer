// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'dart:typed_data';

import 'code.dart';
import 'debug.dart';
import 'op.dart';

typedef _Stack = Float64List;

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

  static final _stack = Float64List(_stackSize ~/ Float64List.bytesPerElement);
  static final _objectStack = <Object?>[];

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
    final instructions = ByteData.sublistView(code.code);
    final objectConstants = code.objectConstants;
    final stack = _stack;
    final objectStack = _objectStack;
    objectStack.clear();
    var sp = -1;
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
          sp = _pushObject(null, sp, stack, objectStack);
          break;
        case OpCode.LoadTrue:
          sp = _pushBool(true, sp, stack);
          break;
        case OpCode.LoadFalse:
          sp = _pushBool(false, sp, stack);
          break;
        case OpCode.LoadNumber:
          final value = _readNumber(instructions, ip);
          ip = _consumeNumber(ip);
          sp = _pushNumber(value, sp, stack);
          break;
        case OpCode.LoadObject:
          final objectId = _readObjectId(instructions, ip);
          ip = _consumeObjectId(ip);
          sp = _pushObject(objectConstants[objectId], sp, stack, objectStack);
          break;
        case OpCode.E:
          sp = _pushNumber(e, sp, stack);
          break;
        case OpCode.Ln2:
          sp = _pushNumber(ln2, sp, stack);
          break;
        case OpCode.Pi:
          sp = _pushNumber(pi, sp, stack);
          break;
        case OpCode.ReturnBool:
          final value = _loadBool(sp, stack);
          sp = _popBool(sp);
          return OkResult(value);
        case OpCode.ReturnNumber:
          final value = _loadNumber(sp, stack);
          sp = _popNumber(sp);
          return OkResult(value);
        case OpCode.ReturnObject:
          final value = _loadObject(objectStack);
          sp = _popObject(sp, objectStack);
          return OkResult(value);
        case OpCode.ReturnError:
          return const ErrorResult('Expression evaluation failed.');
        case OpCode.JumpIfNoError:
          if (!errorFlag) {
            ip = _readJumpAddress(instructions, ip);
          } else {
            errorFlag = false;
            ip = _consumeJumpAddress(ip);
          }
          break;
        case OpCode.SetErrorFlag:
          errorFlag = true;
          break;
        case OpCode.LoadObjectAs:
          final stackOffset = _readStackOffset(instructions, ip);
          ip = _consumeStackOffset(ip);
          final type = _readTypedId(instructions, ip);
          ip = _consumeTypedId(ip);
          final stackIndex = sp - stackOffset;
          final objectStackIndex = stack[stackIndex].toInt();
          final object = objectStack.removeAt(objectStackIndex);

          var checkSucceeded = false;
          switch (type) {
            case 0: // Bool
              if (object is bool) {
                checkSucceeded = true;
                stack[stackIndex] = object ? 1.0 : 0.0;
              }
              break;
            case 1: // Number
              if (object is double) {
                checkSucceeded = true;
                stack[stackIndex] = object;
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
            final valuesToPop = _decodeTotalPopCount(popCount);
            final objectsToPop = _decodeObjectPopCount(popCount);
            sp -= valuesToPop;
            objectStack.removeRange(
              // -1 because we already removed the target object.
              objectStack.length - (objectsToPop - 1),
              objectStack.length,
            );

            // Jump to the error handler.
            final errorHandlerAddress = _readJumpAddress(instructions, ip);
            errorFlag = true;
            ip = errorHandlerAddress;
          }
          break;
        case OpCode.Not:
          _unaryMathOp(sp, stack, _not);
          break;
        case OpCode.Min:
          sp = _binaryMathOp(sp, stack, min);
          break;
        case OpCode.Max:
          sp = _binaryMathOp(sp, stack, max);
          break;
        case OpCode.Add:
          sp = _binaryMathOp(sp, stack, _add);
          break;
        case OpCode.Subtract:
          sp = _binaryMathOp(sp, stack, _subtract);
          break;
        case OpCode.Multiply:
          sp = _binaryMathOp(sp, stack, _multiply);
          break;
        case OpCode.Divide:
          sp = _binaryMathOp(sp, stack, _divide);
          break;
        case OpCode.Modulo:
          sp = _binaryMathOp(sp, stack, _modulo);
          break;
        case OpCode.Pow:
          sp = _binaryMathOp(sp, stack, _pow);
          break;
        case OpCode.Sqrt:
          _unaryMathOp(sp, stack, sqrt);
          break;
        case OpCode.Negate:
          _unaryMathOp(sp, stack, _negate);
          break;
        case OpCode.Abs:
          _unaryMathOp(sp, stack, _abs);
          break;
        case OpCode.Floor:
          _unaryMathOp(sp, stack, _floor);
          break;
        case OpCode.Ceil:
          _unaryMathOp(sp, stack, _ceil);
          break;
        case OpCode.Round:
          _unaryMathOp(sp, stack, _round);
          break;
        case OpCode.Sin:
          _unaryMathOp(sp, stack, sin);
          break;
        case OpCode.Asin:
          _unaryMathOp(sp, stack, asin);
          break;
        case OpCode.Cos:
          _unaryMathOp(sp, stack, cos);
          break;
        case OpCode.Acos:
          _unaryMathOp(sp, stack, acos);
          break;
        case OpCode.Tan:
          _unaryMathOp(sp, stack, tan);
          break;
        case OpCode.Atan:
          _unaryMathOp(sp, stack, atan);
          break;
        case OpCode.Log:
          _unaryMathOp(sp, stack, log);
          break;
        case OpCode.Log2:
          _unaryMathOp(sp, stack, _log2);
          break;
        case OpCode.Log10:
          _unaryMathOp(sp, stack, _log10);
          break;
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
int _decodeTotalPopCount(int popCount) => popCount >> 4;

@pragma('vm:prefer-inline')
int _decodeObjectPopCount(int popCount) => popCount & 0x0F;

@pragma('vm:prefer-inline')
int _pushBool(
  bool value,
  int sp,
  _Stack stack,
) =>
    _pushNumber(value ? 1 : 0, sp, stack);

@pragma('vm:prefer-inline')
int _pushNumber(double value, int sp, _Stack stack) {
  stack[++sp] = value;
  return sp;
}

@pragma('vm:prefer-inline')
int _pushObject(
  Object? value,
  int sp,
  _Stack stack,
  List<Object?> stackObjects,
) {
  final objectId = stackObjects.length;
  stackObjects.add(value);
  stack[++sp] = objectId.toDouble();
  return sp;
}

@pragma('vm:prefer-inline')
bool _loadBool(int sp, _Stack stack) => stack[sp] != 0.0;

@pragma('vm:prefer-inline')
int _popBool(int sp) => sp - 1;

@pragma('vm:prefer-inline')
double _loadNumber(int sp, _Stack stack) => stack[sp];

@pragma('vm:prefer-inline')
int _popNumber(int sp) => sp - 1;

@pragma('vm:prefer-inline')
Object? _loadObject(List<Object?> objectStack) {
  // Since we loading the object at the top of the stack it must be the last
  // object on the object stack and we don't need to look up the index in the
  // stack.
  return objectStack.last;
}

@pragma('vm:prefer-inline')
int _popObject(int sp, List<Object?> objectStack) {
  // Since we are popping the object it must be the last object on the object
  // stack and we don't need to look up the index in the stack.
  objectStack.removeLast();
  return sp - 1;
}

@pragma('vm:prefer-inline')
void _unaryMathOp(int sp, _Stack stack, double Function(double x) op) {
  stack[sp] = op(stack[sp]);
}

@pragma('vm:prefer-inline')
int _binaryMathOp(
  int sp,
  _Stack stack,
  double Function(double a, double b) op,
) {
  final indexB = sp;
  final indexA = indexB - 1;
  final b = stack[indexB];
  final a = stack[indexA];
  stack[indexA] = op(a, b);
  return indexA;
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
