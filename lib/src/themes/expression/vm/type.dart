abstract class ExprType {
  const ExprType();

  String describe();

  bool isAssignableFrom(ExprType other);

  @override
  String toString() => describe();
}

const dynamicType = _DynamicType();

class _DynamicType extends ExprType {
  const _DynamicType();

  @override
  String describe() => 'dynamic';

  @override
  bool isAssignableFrom(ExprType other) => true;
}

const boolType = _BoolType();

class _BoolType extends ExprType {
  const _BoolType();

  @override
  String describe() => 'bool';

  @override
  bool isAssignableFrom(ExprType other) => identical(other, boolType);
}

const numberType = _NumberType();

class _NumberType extends ExprType {
  const _NumberType();

  @override
  String describe() => 'number';

  @override
  bool isAssignableFrom(ExprType other) => identical(other, numberType);
}

const stringType = _StringType();

class _StringType extends ExprType {
  const _StringType();

  @override
  String describe() => 'string';

  @override
  bool isAssignableFrom(ExprType other) => identical(other, stringType);
}

class ArrayType extends ExprType {
  const ArrayType(this.elementType, [this.length]);

  final ExprType elementType;
  final int? length;

  @override
  String describe() {
    final length = this.length;
    if (length != null) {
      return '[${elementType.describe()}; $length]';
    } else {
      return '[${elementType.describe()}]';
    }
  }

  @override
  bool isAssignableFrom(ExprType other) {
    if (other is ArrayType) {
      if (length != null && other.length != null && length != other.length) {
        return false;
      }
      return elementType.isAssignableFrom(other.elementType);
    }
    return false;
  }
}
