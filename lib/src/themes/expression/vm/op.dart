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
  static const Min = 16;
  static const Max = 17;
  static const Add = 18;
  static const Subtract = 19;
  static const Multiply = 20;
  static const Divide = 21;
  static const Modulo = 22;
  static const Pow = 23;
  static const Sqrt = 24;
  static const Negate = 25;
  static const Abs = 26;
  static const Ceil = 27;
  static const Floor = 28;
  static const Round = 29;
  static const Sin = 30;
  static const Asin = 31;
  static const Cos = 32;
  static const Acos = 33;
  static const Tan = 34;
  static const Atan = 35;
  static const Log = 36;
  static const Log2 = 37;
  static const Log10 = 38;
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
  Min(OpCode.Min),
  Max(OpCode.Max),
  Add(OpCode.Add),
  Subtract(OpCode.Subtract),
  Multiply(OpCode.Multiply),
  Divide(OpCode.Divide),
  Modulo(OpCode.Modulo),
  Pow(OpCode.Pow),
  Sqrt(OpCode.Sqrt),
  Negate(OpCode.Negate),
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
