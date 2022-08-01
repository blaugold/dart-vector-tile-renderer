import 'package:collection/collection.dart';

import 'ast.dart';
import 'compiler.dart';
import 'error.dart';
import 'op.dart';
import 'resolver.dart';
import 'type.dart';
import 'vm.dart';

abstract class OperatorDefinition {
  const OperatorDefinition();

  ResolveOperatorResult resolve(List<Expr> arguments, ResolveContext context);

  void compile(OperatorExpr expr, CompileContext context);
}

class ResolveOperatorResult {
  ResolveOperatorResult({
    required this.type,
    required this.mayFail,
    required this.errors,
    required this.isConstant,
    this.constantResult,
  }) : assert(constantResult == null || isConstant);

  final ExprType type;
  final bool mayFail;
  final bool isConstant;
  final ExprResult? constantResult;
  final List<ExprError> errors;
}

bool checkArgumentType(
  Expr argument,
  ExprType parameterType,
  List<ExprError> errors,
) {
  if (parameterType.isAssignableFrom(argument.type)) {
    return false;
  }

  if (dynamicType == argument.type) {
    return true;
  }

  errors.add(
    ExprError(
      argument,
      '${argument.type} is not assignable to $parameterType.',
    ),
  );

  // Does not matter what we return here since the operator will never be
  // executed.
  return false;
}

OperatorDefinition? resolveOperatorDefinition(OperatorExpr expr) {
  switch (expr.name) {
    case 'e':
      return const ConstantOperator(numberType, Op.E);
    case 'ln2':
      return const ConstantOperator(numberType, Op.Ln2);
    case 'pi':
      return const ConstantOperator(numberType, Op.Pi);
    case '!':
      return const SimpleOperatorDefinition(
        Op.Not,
        argumentsType: boolType,
        type: boolType,
        argumentCount: 1,
      );
    // TODO: distance
    // TODO: max, min
    case '+':
      // TODO: Variadic +
      return const BinaryMathOperator(Op.Add);
    case '-':
      // TODO: Unary -
      return const BinaryMathOperator(Op.Subtract);
    case '*':
      // TODO: Variadic *
      return const BinaryMathOperator(Op.Multiply);
    case '/':
      return const BinaryMathOperator(Op.Divide);
    case '%':
      return const BinaryMathOperator(Op.Modulo);
    case '^':
      return const BinaryMathOperator(Op.Pow);
    case 'sqrt':
      return const UnaryMathOperator(Op.Sqrt);
    case 'abs':
      return const UnaryMathOperator(Op.Abs);
    case 'ceil':
      return const UnaryMathOperator(Op.Ceil);
    case 'floor':
      return const UnaryMathOperator(Op.Floor);
    case 'round':
      return const UnaryMathOperator(Op.Round);
    case 'sin':
      return const UnaryMathOperator(Op.Sin);
    case 'asin':
      return const UnaryMathOperator(Op.Asin);
    case 'cos':
      return const UnaryMathOperator(Op.Cos);
    case 'acos':
      return const UnaryMathOperator(Op.Acos);
    case 'tan':
      return const UnaryMathOperator(Op.Tan);
    case 'atan':
      return const UnaryMathOperator(Op.Atan);
    case 'ln':
      return const UnaryMathOperator(Op.Log);
    case 'log2':
      return const UnaryMathOperator(Op.Log2);
    case 'log10':
      return const UnaryMathOperator(Op.Log10);
  }

  return null;
}

class ConstantOperator extends OperatorDefinition {
  const ConstantOperator(this.type, this.op);

  final ExprType type;
  final Op op;

  @override
  ResolveOperatorResult resolve(List<Expr> arguments, ResolveContext context) =>
      ResolveOperatorResult(
        type: type,
        mayFail: false,
        errors: [],
        isConstant: true,
      );

  @override
  void compile(OperatorExpr expr, CompileContext context) =>
      context.code.writeOp(op);
}

class SimpleOperatorDefinition extends OperatorDefinition {
  const SimpleOperatorDefinition(
    this.op, {
    required this.argumentsType,
    required this.type,
    required this.argumentCount,
  });

  final Op op;
  final ExprType argumentsType;
  final ExprType type;
  final int argumentCount;

  @override
  ResolveOperatorResult resolve(List<Expr> arguments, ResolveContext context) {
    var mayFail = false;
    final errors = <ExprError>[];

    arguments.forEachIndexed((index, argument) {
      if (index < argumentCount) {
        mayFail = mayFail ||
            argument.mayFail ||
            checkArgumentType(argument, argumentsType, errors);
      } else {
        errors.add(ExprError(argument, 'Unexpected argument.'));
      }
    });

    return ResolveOperatorResult(
      type: type,
      mayFail: mayFail,
      errors: errors,
      isConstant: arguments.every((argument) => argument.isConstant),
    );
  }

  @override
  void compile(OperatorExpr expr, CompileContext context) {
    // Evaluate all arguments beforehand.
    expr.arguments.forEach(context.compileExpr);

    // Generate type checks for dynamic arguments.
    var dynamicArguments =
        expr.arguments.where((argument) => argument.type == dynamicType).length;

    expr.arguments.reversed.forEachIndexed((index, argument) {
      if (argument.type == dynamicType) {
        context.code.loadObjectAs(
          offset: index,
          type: argumentsType,
          valuesToPop: expr.arguments.length,
          objectsToPop: dynamicArguments--,
          errorHandler: context.errorHandler,
        );
      }
    });

    // Generate the operator call.
    for (var i = 0; i < argumentCount; i++) {
      context.pop();
    }
    context.code.writeOp(op);
  }
}

class UnaryMathOperator extends SimpleOperatorDefinition {
  const UnaryMathOperator(super.op)
      : super(
          argumentsType: numberType,
          type: numberType,
          argumentCount: 1,
        );
}

class BinaryMathOperator extends SimpleOperatorDefinition {
  const BinaryMathOperator(super.op)
      : super(
          argumentsType: numberType,
          type: numberType,
          argumentCount: 2,
        );
}
