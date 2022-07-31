import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/code.dart';
import 'package:vector_tile_renderer/src/themes/expression/vm/vm.dart';

void main() {
  test('sandbox', () {
    final vm = VM();

    final builder = CodeBuilder();
    int constant;

    constant = builder.addConstant(1);
    builder.writeOp(Op.Constant);
    builder.write(constant);

    constant = builder.addConstant(2);
    builder.writeOp(Op.Constant);
    builder.write(constant);

    builder.writeOp(Op.Print);
    builder.writeOp(Op.Return);

    final code = builder.build();

    vm.run(code);
  });
}
