import 'ast.dart';

/// An error related to an expression.
class ExprError {
  ExprError(this.expr, this.message);

  /// Message describing the error that occurred in relation to [expr].
  final String message;

  /// The expression that the caused the error.
  ///
  /// This may be an [ErrorExpr] if the error occurred while parsing to indicate
  /// the location of the error.
  final Expr expr;

  @override
  String toString() => 'ExprError: $message\n${expr.errorLocation()}';
}
