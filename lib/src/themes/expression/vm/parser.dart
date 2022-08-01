import 'ast.dart';
import 'error.dart';

class ExprParser {
  final _errors = <ExprError>[];

  bool get hadError => _errors.isNotEmpty;

  List<ExprError> get errors => List.of(_errors);

  Expr parse(Object? json) {
    _errors.clear();
    return RootExpr(_parse(json));
  }

  void _error(Expr expr, String message) {
    _errors.add(ExprError(expr, message));
  }

  ErrorExpr _errorExpr(String message) {
    final expr = ErrorExpr();
    _error(expr, message);
    return expr;
  }

  Expr _parse(Object? json) {
    if (json == null || json is String || json is bool) {
      return LiteralExpr(json);
    }

    if (json is num) {
      return LiteralExpr(json.toDouble());
    }

    if (json is List<Object?> && json.isNotEmpty) {
      final operatorName = json.first;
      if (operatorName is String) {
        return _parseOperatorExpr(operatorName, json.sublist(1));
      }
    }

    return _errorExpr('Unsupported expression syntax: $json');
  }

  Expr _parseOperatorExpr(String name, List<Object?> arguments) =>
      OperatorExpr(name, arguments.map(_parse).toList(growable: false));
}
