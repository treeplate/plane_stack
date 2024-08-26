class Instruction {
  Instruction(this.boxName, this.inputs);
  final String boxName;
  final List<Input> inputs;
  String toString() => "${inputs.join(', ')} => $boxName";
}

abstract class Input {}

class FromStack extends Input {
  String toString() => "plane from stack";
}

class ConstantNumber extends Input {
  ConstantNumber(this.number);
  final int number;
  String toString() => "$number";
}

class FromUser extends Input {
  String toString() => 'asking for $desc';
  final String desc;

  FromUser(this.desc);
}
