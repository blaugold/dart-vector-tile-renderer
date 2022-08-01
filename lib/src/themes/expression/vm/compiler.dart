import 'ast.dart';
import 'code.dart';
import 'debug.dart';
import 'op.dart';
import 'operator.dart';
import 'type.dart';
import 'vm.dart';

class ExprCompiler {
  Code compile(Expr expr) {
    final context = _CompileContext();
    context._evaluateExpr(expr);
    final code = context._code.build();

    if (debugExprCompilerPrintCode) {
      // ignore: avoid_print
      print(code.disassemble());
    }

    return code;
  }
}

abstract class CompileContext {
  CodeBuilder get code;

  CodeLocation get errorHandler;

  void compileExpr(Expr expr);

  Expr peek(int offset);

  Expr pop();

  void beginErrorHandlerBlock();

  void endErrorHandlerBlock();
}

class _CompileContext implements CompileContext, ExprVisitor<void> {
  final _code = CodeBuilder();
  final _stack = <Expr>[];
  final _errorHandlerLocationStack = <CodeLocation>[];

  @override
  CodeBuilder get code => _code;

  @override
  CodeLocation get errorHandler => _errorHandlerLocationStack.last;

  @override
  void visitRootExpr(RootExpr expr) {
    compileExpr(expr.expr);
    // The root expression is just a pass-through. We pop the compiled child
    // expression before continuing so that the expression stack correctly
    // reflects the stack of values.
    pop();
  }

  @override
  void visitLiteralExpr(LiteralExpr expr) => _loadConstant(expr.value);

  @override
  void visitOperatorExpr(OperatorExpr expr) {
    final operatorDefinition = resolveOperatorDefinition(expr);
    if (operatorDefinition == null) {
      throw UnsupportedError('Unsupported operator: ${expr.name}');
    }
    operatorDefinition.compile(expr, this);
  }

  @override
  void compileExpr(Expr expr) {
    if (expr.hasConstantResult) {
      _loadConstantResult(expr.constantResult);
    } else {
      expr.accept(this);
    }
    _push(expr);
  }

  void _push(Expr expr) => _stack.add(expr);

  @override
  Expr peek(int offset) => _stack[_stack.length - 1 - offset];

  @override
  Expr pop() => _stack.removeLast();

  @override
  void beginErrorHandlerBlock() =>
      _errorHandlerLocationStack.add(_code.createLocation());

  @override
  void endErrorHandlerBlock() =>
      _errorHandlerLocationStack.removeLast().finalize();

  void _loadConstant(Object? value) {
    if (value == null) {
      _code.writeOp(Op.LoadNull);
    } else if (value is bool) {
      _code.writeOp(value ? Op.LoadTrue : Op.LoadFalse);
    } else if (value is double) {
      _code.loadNumberConstant(value);
    } else if (value is String) {
      _code.loadObjectConstant(value);
    } else {
      throw UnsupportedError('Unsupported constant type: ${value.runtimeType}');
    }
  }

  void _loadConstantResult(ExprResult result) {
    if (result is OkResult) {
      _loadConstant(result.value);
    } else if (result is ErrorResult) {
      code.writeOp(Op.SetErrorFlag);
    } else {
      assert(
        false,
        'Unsupported expression result type: ${result.runtimeType}',
      );
    }
  }

  void _returnLastValue() {
    assert(
      _stack.length == 1,
      'Expected exactly one value on the stack but found ${_stack.length}.',
    );
    final type = pop().type;
    if (type == boolType) {
      _code.writeOp(Op.ReturnBool);
    } else if (type == numberType) {
      _code.writeOp(Op.ReturnNumber);
    } else if (type == stringType) {
      _code.writeOp(Op.ReturnObject);
    }
  }

  void _evaluateExpr(Expr expr) {
    if (expr.mayFail) {
      beginErrorHandlerBlock();
    }

    compileExpr(expr);

    CodeLocation? returnValueLocation;
    if (expr.mayFail) {
      endErrorHandlerBlock();
      returnValueLocation = code.jumpIfNoError();
      code.writeOp(Op.ReturnError);
    }

    returnValueLocation?.finalize();
    _returnLastValue();
  }
}
