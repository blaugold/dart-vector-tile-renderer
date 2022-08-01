// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: constant_identifier_names

class OpCode {
  // Constants
  static const LoadNull = 0;
  static const LoadTrue = 1;
  static const LoadFalse = 2;
  static const LoadNumber = 3;
  static const LoadObject = 4;
  static const E = 5;
  static const Ln2 = 6;
  static const Pi = 7;

  // Control flow
  static const ReturnBool = 8;
  static const ReturnNumber = 9;
  static const ReturnObject = 10;
  static const ReturnError = 11;
  static const JumpIfNoError = 12;
  static const SetErrorFlag = 13;

  // Type checks
  static const LoadObjectAs = 14;

  // Boolean logic
  static const Not = 15;

  // Arithmetic
  static const Add = 16;
  static const Subtract = 17;
  static const Multiply = 18;
  static const Divide = 19;
  static const Modulo = 20;
  static const Pow = 21;
  static const Sqrt = 22;
  static const Abs = 23;
  static const Ceil = 24;
  static const Floor = 25;
  static const Round = 26;
  static const Sin = 27;
  static const Asin = 28;
  static const Cos = 29;
  static const Acos = 30;
  static const Tan = 31;
  static const Atan = 32;
  static const Log = 33;
  static const Log2 = 34;
  static const Log10 = 35;
}

enum Op {
  // Constants
  LoadNull(OpCode.LoadNull),
  LoadTrue(OpCode.LoadTrue),
  LoadFalse(OpCode.LoadFalse),
  LoadNumber(OpCode.LoadNumber),
  LoadObject(OpCode.LoadObject),
  E(OpCode.E),
  Ln2(OpCode.Ln2),
  Pi(OpCode.Pi),
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
  Pow(OpCode.Pow),
  Sqrt(OpCode.Sqrt),
  Abs(OpCode.Abs),
  Ceil(OpCode.Ceil),
  Floor(OpCode.Floor),
  Round(OpCode.Round),
  Sin(OpCode.Sin),
  Asin(OpCode.Asin),
  Cos(OpCode.Cos),
  Acos(OpCode.Acos),
  Tan(OpCode.Tan),
  Atan(OpCode.Atan),
  Log(OpCode.Log),
  Log2(OpCode.Log2),
  Log10(OpCode.Log10);

  const Op(this.code);

  final int code;
}
