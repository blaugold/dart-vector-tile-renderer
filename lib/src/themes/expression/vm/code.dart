// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'type.dart';

class OpCode {
  // Constants
  static const LoadNull = 0;
  static const LoadTrue = 1;
  static const LoadFalse = 2;
  static const LoadNumberConstant = 3;
  static const LoadObjectConstant = 4;
  // Print
  static const PrintBool = 5;
  static const PrintNumber = 6;
  static const PrintObject = 7;
  // Control flow
  static const ReturnBool = 8;
  static const ReturnNumber = 9;
  static const ReturnObject = 10;
  static const ReturnError = 11;
  static const JumpIfNoError = 12;
  static const LoadObjectAs = 13;
  static const SetErrorFlag = 14;
  // Math
  static const Add = 15;
  static const Subtract = 16;
  static const Multiply = 17;
  static const Divide = 18;
  static const Modulo = 19;
  static const Pow = 20;
  // Boolean
  static const Not = 21;
}

enum Op {
  LoadNull(OpCode.LoadNull),
  LoadTrue(OpCode.LoadTrue),
  LoadFalse(OpCode.LoadFalse),
  LoadNumberConstant(OpCode.LoadNumberConstant),
  LoadObjectConstant(OpCode.LoadObjectConstant),
  PrintBool(OpCode.PrintBool),
  PrintNumber(OpCode.PrintNumber),
  PrintObject(OpCode.PrintObject),
  ReturnBool(OpCode.ReturnBool),
  ReturnNumber(OpCode.ReturnNumber),
  ReturnObject(OpCode.ReturnObject),
  ReturnError(OpCode.ReturnError),
  JumpIfNoError(OpCode.JumpIfNoError),
  LoadObjectAs(OpCode.LoadObjectAs),
  SetErrorFlag(OpCode.SetErrorFlag),
  Add(OpCode.Add),
  Subtract(OpCode.Subtract),
  Multiply(OpCode.Multiply),
  Divide(OpCode.Divide),
  Modulo(OpCode.Modulo),
  Pow(OpCode.Pow),
  Not(OpCode.Not);

  const Op(this.code);

  final int code;
}

class CodeLocation {
  CodeLocation._(this._code);

  final CodeBuilder _code;
  int? _offset;

  void finalize() {
    if (_offset != null) {
      throw StateError('Location already finalized.');
    }
    _offset = _code.length;
  }
}

class CodeBuilder {
  CodeBuilder() : _objectConstants = <Object?>[];

  static final _byteData2 = ByteData(2);
  static final _byteData2Uint8List = _byteData2.buffer.asUint8List();
  static final _byteData8 = ByteData(8);
  static final _byteData8Uint8List = _byteData8.buffer.asUint8List();

  final _code = BytesBuilder(copy: true);
  final List<Object?> _objectConstants;
  final _locations = <MapEntry<int, CodeLocation>>[];

  int get length => _code.length;

  CodeLocation createLocation() => CodeLocation._(this);

  void writeOp(Op op) => _writeUint8(op.index);

  void _writeLocation(CodeLocation location) {
    _locations.add(MapEntry(_code.length, location));
    _writeUint16(0);
  }

  void loadNumberConstant(double number) {
    writeOp(Op.LoadNumberConstant);
    _writeFloat64(number);
  }

  void loadObjectConstant(Object? value) {
    writeOp(Op.LoadObjectConstant);
    final constantId = _addConstant(value);
    if (constantId >= 0xFF) {
      throw StateError('LoadObjectConstant only supports 256 constants.');
    }
    _writeUint8(constantId);
  }

  CodeLocation jumpIfNoError([CodeLocation? location]) {
    location ??= createLocation();
    writeOp(Op.JumpIfNoError);
    _writeLocation(location);
    return location;
  }

  void loadObjectAs({
    required int offset,
    required ExprType type,
    required int valuesToPop,
    required int objectsToPop,
    required CodeLocation errorHandler,
  }) {
    if (offset >= 0xFF) {
      throw ArgumentError('CheckType only supports 256 stack offsets.');
    }

    if (valuesToPop >= 0x0F) {
      throw ArgumentError('CheckType can pop at most 16 values.');
    }
    if (objectsToPop >= 0x0F) {
      throw ArgumentError('CheckType can pop ast most 16 objects.');
    }
    if (objectsToPop > valuesToPop) {
      throw ArgumentError(
        'CheckType cannot pop more objects than total values.',
      );
    }

    writeOp(Op.LoadObjectAs);
    _writeUint8(offset);
    if (type == boolType) {
      _writeUint8(0);
    } else if (type == numberType) {
      _writeUint8(1);
    } else {
      throw UnsupportedError('CheckType does not support $type.');
    }
    _writeUint8((valuesToPop << 4) | objectsToPop);
    _writeLocation(errorHandler);
  }

  Code build() {
    final code = _code.takeBytes();
    final objectConstants = List.of(_objectConstants);
    _objectConstants.clear();
    _patchLocations(code);
    _locations.clear();
    return Code(code: code, objectConstants: objectConstants);
  }

  void _writeUint8(int value) {
    assert(value >= 0 && value < 0xFF);
    _code.addByte(value);
  }

  void _writeUint16(int value) {
    assert(value >= 0 && value < 0xFFFF);
    _byteData2.setUint16(0, value);
    _code.add(_byteData2Uint8List);
  }

  int _addConstant(Object? value) {
    _objectConstants.add(value);
    return _objectConstants.length - 1;
  }

  void _writeFloat64(double value) {
    _byteData8.setFloat64(0, value, Endian.host);
    _code.add(_byteData8Uint8List);
  }

  void _patchLocations(Uint8List code) {
    final codeView = ByteData.sublistView(code);
    for (final entry in _locations) {
      final offset = entry.key;
      final location = entry.value;

      if (location._offset == null) {
        throw StateError('Location not finalized.');
      }
      if (location._offset! >= 0xFFFF) {
        throw StateError('Location offset too large: $location._offset}.');
      }

      codeView.setUint16(offset, location._offset!, Endian.host);
    }
  }
}

class Code {
  Code({
    required this.code,
    required this.objectConstants,
  });

  final Uint8List code;
  final List<Object?> objectConstants;
}
