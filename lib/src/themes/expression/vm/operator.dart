import 'package:collection/collection.dart';

import 'ast.dart';
import 'code.dart';
import 'compiler.dart';
import 'error.dart';
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
    case '+':
      return const BinaryMathOperator(Op.Add);
    case '-':
      return const BinaryMathOperator(Op.Subtract);
    case '*':
      return const BinaryMathOperator(Op.Multiply);
    case '/':
      return const BinaryMathOperator(Op.Divide);
    case '%':
      return const BinaryMathOperator(Op.Modulo);
    case '^':
      return const BinaryMathOperator(Op.Pow);
    case '!':
      return const SimpleOperatorDefinition(
        Op.Not,
        argumentsType: boolType,
        type: boolType,
        argumentCount: 1,
      );
    default:
      return null;
  }
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
