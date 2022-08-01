import 'dart:math';

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

  ResolveOperatorResult resolve(OperatorExpr expr, ResolveContext context);

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
        minArgumentCount: 1,
        maxArgumentCount: 1,
      );
    // TODO: distance
    case 'min':
      return const NaryMathOperator(Op.Min);
    case 'max':
      return const NaryMathOperator(Op.Max);
    case '+':
      return const NaryMathOperator(Op.Add);
    case '-':
      if (expr.arguments.length == 1) {
        return const UnaryMathOperator(Op.Negate);
      }
      return const BinaryMathOperator(Op.Subtract);
    case '*':
      return const NaryMathOperator(Op.Multiply);
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
  ResolveOperatorResult resolve(OperatorExpr expr, ResolveContext context) =>
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

class UnaryMathOperator extends SimpleOperatorDefinition {
  const UnaryMathOperator(super.op)
      : super(
          argumentsType: numberType,
          type: numberType,
          minArgumentCount: 1,
          maxArgumentCount: 1,
        );
}

class BinaryMathOperator extends SimpleOperatorDefinition {
  const BinaryMathOperator(super.op)
      : super(
          argumentsType: numberType,
          type: numberType,
          minArgumentCount: 2,
          maxArgumentCount: 2,
        );
}

class NaryMathOperator extends SimpleOperatorDefinition {
  const NaryMathOperator(super.op)
      : super(
          argumentsType: numberType,
          type: numberType,
          minArgumentCount: 2,
          maxArgumentCount: null,
        );
}

class SimpleOperatorDefinition extends OperatorDefinition {
  const SimpleOperatorDefinition(
    this.op, {
    required this.argumentsType,
    required this.type,
    required this.minArgumentCount,
    required this.maxArgumentCount,
  });

  final Op op;
  final ExprType argumentsType;
  final ExprType type;
  final int minArgumentCount;
  final int? maxArgumentCount;

  @override
  ResolveOperatorResult resolve(
    OperatorExpr expr,
    ResolveContext context,
  ) {
    var mayFail = false;
    final errors = <ExprError>[];

    if (expr.arguments.length < minArgumentCount) {
      errors.add(
        ExprError(
          expr,
          'Expected at least $minArgumentCount arguments, but got '
          '${expr.arguments.length}.',
        ),
      );
    }

    final maxArgumentCount = this.maxArgumentCount;
    expr.arguments.forEachIndexed((index, argument) {
      if (maxArgumentCount == null || index < maxArgumentCount) {
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
      isConstant: expr.arguments.every((argument) => argument.isConstant),
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

    // Generate the operator calls.
    final argumentCount = expr.arguments.length;
    if (argumentCount > 1) {
      context.pop();
    }
    for (var i = 0; i < max(argumentCount - 1, 1); i++) {
      context.pop();
      context.code.writeOp(op);
    }
  }
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
