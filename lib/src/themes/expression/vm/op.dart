// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: constant_identifier_names

class OpCode {
  // Constants
  static const LoadNull = 0;
  static const LoadTrue = 1;
  static const LoadFalse = 2;
  static const LoadNumber = 3;
  static const LoadObject = 4;

  // Control flow
  static const ReturnBool = 5;
  static const ReturnNumber = 6;
  static const ReturnObject = 7;
  static const ReturnError = 8;
  static const JumpIfNoError = 9;
  static const SetErrorFlag = 10;

  // Type checks
  static const LoadObjectAs = 11;

  // Boolean logic
  static const Not = 12;

  // Arithmetic
  static const Add = 13;
  static const Subtract = 14;
  static const Multiply = 15;
  static const Divide = 16;
  static const Modulo = 17;
  static const Pow = 18;
}

enum Op {
  // Constants
  LoadNull(OpCode.LoadNull),
  LoadTrue(OpCode.LoadTrue),
  LoadFalse(OpCode.LoadFalse),
  LoadNumber(OpCode.LoadNumber),
  LoadObject(OpCode.LoadObject),
  // Control flow
  ReturnBool(OpCode.ReturnBool),
  ReturnNumber(OpCode.ReturnNumber),
  ReturnObject(OpCode.ReturnObject),
  ReturnError(OpCode.ReturnError),
  JumpIfNoError(OpCode.JumpIfNoError),
  SetErrorFlag(OpCode.SetErrorFlag),
  // Type checks
  LoadObjectAs(OpCode.LoadObjectAs),
  // Boolean logic
  Not(OpCode.Not),
  // Arithmetic
  Add(OpCode.Add),
  Subtract(OpCode.Subtract),
  Multiply(OpCode.Multiply),
  Divide(OpCode.Divide),
  Modulo(OpCode.Modulo),
  Pow(OpCode.Pow);

  const Op(this.code);

  final int code;
}
