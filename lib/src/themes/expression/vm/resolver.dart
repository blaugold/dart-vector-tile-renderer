import 'ast.dart';
import 'compiler.dart';
import 'error.dart';
import 'operator.dart';
import 'type.dart';
import 'vm.dart';

class ExprResolver extends ExprVisitor<void> {
  final _context = _ResolveContext();
  final _errors = <ExprError>[];

  bool get hadError => _errors.isNotEmpty;

  List<ExprError> get errors => List.of(_errors);

  void resolve(Expr expr) {
    _errors.clear();
    _resolve(expr);
  }

  void _resolve(Expr expr) => expr.accept(this);

  @override
  void visitRootExpr(RootExpr expr) {
    _resolve(expr.expr);
    expr
      ..type = expr.expr.type
      ..mayFail = expr.expr.mayFail
      ..isConstant = expr.expr.isConstant;

    if (expr.isConstant) {
      _context.evaluateConstant(expr);
    }
  }

  @override
  void visitLiteralExpr(LiteralExpr expr) {
    final value = expr.value;
    if (value == null) {
      expr.type = dynamicType;
    } else if (value is bool) {
      expr.type = boolType;
    } else if (value is double) {
      expr.type = numberType;
    } else if (value is String) {
      expr.type = stringType;
    } else {
      _error(expr, 'Unsupported literal type: ${value.runtimeType}');
    }

    expr
      ..mayFail = false
      ..isConstant = true
      ..constantResult = OkResult(value);
  }

  @override
  void visitOperatorExpr(OperatorExpr expr) {
    for (final argument in expr.arguments) {
      _resolve(argument);
    }

    final operatorDefinition = resolveOperatorDefinition(expr);
    if (operatorDefinition == null) {
      _error(expr, 'Unknown operator: ${expr.name}');
      return;
    }
    final resolveResult = operatorDefinition.resolve(expr.arguments, _context);

    expr
      ..type = resolveResult.type
      ..mayFail = resolveResult.mayFail
      ..isConstant = resolveResult.isConstant;

    if (resolveResult.isConstant) {
      final constantResult = resolveResult.constantResult;
      if (constantResult != null) {
        expr.constantResult = constantResult;
      }
    }

    _errors.addAll(resolveResult.errors);
  }

  void _error(Expr expr, String message) =>
      _errors.add(ExprError(expr, message));
}

abstract class ResolveContext {
  ExprResult evaluateConstant(Expr expr);
}

class _ResolveContext implements ResolveContext {
  // Compiler and VM to evaluate constant expressions.
  static final _constantCompiler = ExprCompiler();
  static final _constantVM = ExprVM();

  @override
  ExprResult evaluateConstant(Expr expr) {
    assert(expr.isConstant);

    if (!expr.hasConstantResult) {
      expr.constantResult = _constantVM.run(_constantCompiler.compile(expr));
    }

    return expr.constantResult;
  }
}
