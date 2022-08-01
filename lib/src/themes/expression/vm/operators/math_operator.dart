import 'package:collection/collection.dart';

import '../ast.dart';
import '../code.dart';
import '../compiler.dart';
import '../error.dart';
import '../operator.dart';
import '../resolver.dart';
import '../type.dart';

class BinaryMathOperatorDefinition extends OperatorDefinition {
  const BinaryMathOperatorDefinition(this.op);

  final Op op;

  @override
  ResolveOperatorResult resolve(List<Expr> arguments, ResolveContext context) {
    var mayFail = false;
    final errors = <ExprError>[];

    arguments.forEachIndexed((index, argument) {
      if (index < 2) {
        mayFail = mayFail ||
            argument.mayFail ||
            checkArgumentType(argument, numberType, errors);
      } else {
        errors.add(ExprError(argument, 'Unexpected argument.'));
      }
    });

    return ResolveOperatorResult(
      type: numberType,
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
          type: numberType,
          valuesToPop: expr.arguments.length,
          objectsToPop: dynamicArguments--,
          errorHandler: context.errorHandler,
        );
      }
    });

    // Generate the operator call.
    context.pop();
    context.pop();
    context.code.writeOp(op);
  }
}
