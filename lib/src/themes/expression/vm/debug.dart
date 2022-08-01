import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'code.dart';
import 'op.dart';

const debugExprCompilerPrintCode = true;
const debugExprVMTraceExecution = true;

extension DisassembleExt on Code {
  String disassemble() {
    final buffer = StringBuffer();
    buffer.writeln('=== Disassembly Start ===');
    final data = ByteData.sublistView(code);
    var offset = 0;
    while (offset < data.lengthInBytes) {
      try {
        offset = _disassembleInstruction(data, offset, buffer);
        buffer.writeln();
      } catch (e) {
        buffer.writeln();
        buffer.write('Error: $e');
        break;
      }
    }
    buffer.write('=== Disassembly End   ===');
    return buffer.toString();
  }

  String disassembleInstruction(int offset, [ByteData? code]) {
    code ??= ByteData.sublistView(this.code);
    final buffer = StringBuffer();
    _disassembleInstruction(code, offset, buffer);
    return buffer.toString();
  }

  int _disassembleInstruction(ByteData code, int offset, StringBuffer buffer) {
    buffer.writeInstructionAddress(offset);
    buffer.write(' ');

    final opCode = code.getUint8(offset++);
    final op = Op.values.firstWhereOrNull((element) => element.code == opCode);
    if (op == null) {
      throw StateError('Invalid op code: $opCode.');
    }
    buffer.write(op.name);
    buffer.write(' ');

    switch (op) {
      case Op.LoadNull:
      case Op.LoadTrue:
      case Op.LoadFalse:
        break;
      case Op.LoadNumber:
        final value = code.getFloat64(offset, Endian.host);
        offset += Float64List.bytesPerElement;
        buffer.write(value);
        break;
      case Op.LoadObject:
        final constantId = code.getUint8(offset++);
        buffer.write(objectConstants[constantId]);
        buffer.write(' ');
        buffer.writeId(constantId);
        break;
      case Op.E:
      case Op.Ln2:
      case Op.Pi:
      case Op.ReturnBool:
      case Op.ReturnNumber:
      case Op.ReturnObject:
      case Op.ReturnError:
        break;
      case Op.JumpIfNoError:
        final jumpAddress = code.getUint16(offset, Endian.host);
        offset += Uint16List.bytesPerElement;
        buffer.write('-> ');
        buffer.writeInstructionAddress(jumpAddress);
        break;
      case Op.SetErrorFlag:
        break;
      case Op.LoadObjectAs:
        final stackOffset = code.getUint8(offset++);
        buffer.write('[');
        buffer.write(stackOffset);
        buffer.write(']; ');

        final typeId = code.getUint8(offset++);
        switch (typeId) {
          case 0:
            buffer.write('bool');
            break;
          case 1:
            buffer.write('number');
            break;
          default:
            throw StateError('Unknown type id: $typeId.');
        }
        buffer.write(' ');
        buffer.writeId(typeId);

        final encodedValuesToPop = code.getUint8(offset++);
        final valuesToPop = encodedValuesToPop >> 4;
        final objectsToPop = encodedValuesToPop & 0x0F;
        buffer.write(' pop ');
        buffer.write(valuesToPop);
        buffer.write(' value(s) including ');
        buffer.write(objectsToPop);
        buffer.write(' object(s); ');

        final jumpAddress = code.getUint16(offset, Endian.host);
        offset += Uint16List.bytesPerElement;
        buffer.write('error handler -> ');
        buffer.writeInstructionAddress(jumpAddress);
        break;
      case Op.Not:
      case Op.Add:
      case Op.Subtract:
      case Op.Multiply:
      case Op.Divide:
      case Op.Modulo:
      case Op.Pow:
      case Op.Sqrt:
      case Op.Abs:
      case Op.Ceil:
      case Op.Floor:
      case Op.Round:
      case Op.Sin:
      case Op.Asin:
      case Op.Cos:
      case Op.Acos:
      case Op.Tan:
      case Op.Atan:
      case Op.Log:
      case Op.Log2:
      case Op.Log10:
        break;
    }

    return offset;
  }
}

extension on StringBuffer {
  void writeInstructionAddress(int address) {
    write('0x');
    write(address.toRadixString(16).padLeft(4, '0'));
  }

  void writeId(int id) {
    write('(#');
    write(id);
    write(');');
  }
}
