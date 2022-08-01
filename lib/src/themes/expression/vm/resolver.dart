import 'ast.dart';
import 'compiler.dart';
import 'error.dart';
import 'operator.dart';
import 'type.dart';
import 'vm.dart';

class ExprResolver extends ExprVisitor<void> {
  var _context = _ResolveContext();

  bool get hadError => errors.isNotEmpty;

  List<ExprError> get errors => _context.errors;

  void resolve(Expr expr) {
    _context = _ResolveContext();
    _resolve(expr);
    _context._debugClose();
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
      _context.error(expr, 'Unsupported literal type: ${value.runtimeType}');
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
      _context.error(expr, 'Unknown operator: ${expr.name}');
      return;
    }
    final resolveResult = operatorDefinition.resolve(expr, _context);

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
  }
}

abstract class ResolveContext {
  bool get hadError;

  List<ExprError> get errors;

  void error(Expr expr, String message);

  ExprResult evaluateConstant(Expr expr);
}

class _ResolveContext implements ResolveContext {
  // Compiler and VM to evaluate constant expressions.
  static final _constantCompiler = ExprCompiler();
  static final _constantVM = ExprVM();

  final _errors = <ExprError>[];
  var _debugIsClosed = false;

  @override
  bool get hadError => _errors.isNotEmpty;

  @override
  List<ExprError> get errors => List.unmodifiable(_errors);

  void _debugClose() {
    assert(
      () {
        _debugIsClosed = true;
        return true;
      }(),
    );
  }

  void _debugAssertIsNotClosed() {
    assert(!_debugIsClosed);
  }

  @override
  void error(Expr expr, String message) {
    _debugAssertIsNotClosed();
    _errors.add(ExprError(expr, message));
  }

  @override
  ExprResult evaluateConstant(Expr expr) {
    _debugAssertIsNotClosed();

    assert(expr.isConstant);

    if (hadError) {
      return const ErrorResult(
        'Cannot evaluate constant expression when resolve errors exist.',
      );
    }

    if (!expr.hasConstantResult) {
      expr.constantResult = _constantVM.run(_constantCompiler.compile(expr));
    }

    return expr.constantResult;
  }
}
