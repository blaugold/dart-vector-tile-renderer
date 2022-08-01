import 'type.dart';
import 'vm.dart';

abstract class Expr {
  T accept<T>(ExprVisitor<T> visitor);

  /// The parent of this expression in the AST.
  ///
  /// [RootExpr] is its own parent.
  late final Expr parent;

  /// The type of the value returned by evaluating this expression.
  late final ExprType type;

  /// Whether evaluation of this expression may fail.
  ///
  /// If evaluation of an expression fails no value is available.
  late final bool mayFail;

  /// Whether this expression evaluates to a constant result.
  late final bool isConstant;

  /// Whether this expression has been evaluated to a constant result.
  bool get hasConstantResult => _constantResult != null;

  /// The constant result of this expression, if it [isConstant].
  ExprResult get constantResult {
    assert(hasConstantResult);
    return _constantResult!;
  }

  set constantResult(ExprResult result) {
    assert(isConstant);
    assert(!hasConstantResult);
    _constantResult = result;
  }

  ExprResult? _constantResult;

  String errorLocation() {
    var result = '<${errorRepresentation()}>';
    var self = this;
    var parent = this.parent;
    do {
      result = parent.childErrorLocation(self, result);
      self = parent;
      parent = parent.parent;
    } while (self is! RootExpr);
    return result;
  }

  String errorRepresentation();

  String childErrorLocation(Expr child, String childString);
}

abstract class ExprVisitor<T> {
  T visitRootExpr(RootExpr expr);
  T visitLiteralExpr(LiteralExpr expr);
  T visitOperatorExpr(OperatorExpr expr);
}

class RootExpr extends Expr {
  RootExpr(this.expr) {
    parent = expr.parent = this;
  }

  final Expr expr;

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitRootExpr(this);

  @override
  String errorRepresentation() => '...';

  @override
  String childErrorLocation(Expr child, String childString) {
    assert(expr == child || this == child);
    return '\$($childString)';
  }
}

/// Pseudo expression that is placed in the AST during parsing to indicate the
/// error location.
class ErrorExpr extends Expr {
  @override
  T accept<T>(ExprVisitor<T> visitor) => throw UnimplementedError();

  @override
  String errorRepresentation() => 'ERROR';

  @override
  String childErrorLocation(Expr child, String childString) =>
      throw UnsupportedError('ErrorExpr has no children.');
}

class LiteralExpr extends Expr {
  final Object? value;

  LiteralExpr(this.value);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitLiteralExpr(this);

  @override
  String errorRepresentation() => value.toString();

  @override
  String childErrorLocation(Expr child, String childString) =>
      throw UnsupportedError('LiteralExpr has no children.');
}

class OperatorExpr extends Expr {
  OperatorExpr(this.name, this.arguments) {
    for (final arg in arguments) {
      arg.parent = this;
    }
  }

  final String name;
  final List<Expr> arguments;

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitOperatorExpr(this);

  @override
  String errorRepresentation() => '$name(...)';

  @override
  String childErrorLocation(Expr child, String childString) {
    final index = arguments.indexOf(child);
    if (index == -1) {
      throw UnsupportedError('Not a child of this expression.');
    }

    final args = <String>[];

    for (var i = 0; i < arguments.length; i++) {
      if (i == index) {
        args.add(childString);
      } else {
        args.add('_');
      }
    }

    return '$name(${args.join(', ')})';
  }
}
