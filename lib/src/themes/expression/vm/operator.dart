import 'ast.dart';
import 'code.dart';
import 'compiler.dart';
import 'error.dart';
import 'operators/math_operator.dart';
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
      return const BinaryMathOperatorDefinition(Op.Add);
    case '-':
      return const BinaryMathOperatorDefinition(Op.Subtract);
    case '*':
      return const BinaryMathOperatorDefinition(Op.Multiply);
    case '/':
      return const BinaryMathOperatorDefinition(Op.Divide);
    case '%':
      return const BinaryMathOperatorDefinition(Op.Modulo);
    case '^':
      return const BinaryMathOperatorDefinition(Op.Pow);
    default:
      return null;
  }
}
