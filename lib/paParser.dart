import 'pa.dart';

Iterable<Instruction> parsePA(String fileData) sync* {
  List<String> lines = fileData.split('\n');
  for (String line in lines) {
    Iterator<String> parts = line.split(' ').iterator;
    parts.moveNext();
    yield Instruction(parts.current, parsePAInputs(parts).toList());
  }
}

Iterable<Input> parsePAInputs(Iterator<String> parts) sync* {
  while (parts.moveNext()) {
    switch (parts.current) {
      case 'istack':
        yield FromStack();
        break;
      case 'const':
        assert(parts.moveNext());
        int n = int.parse(parts.current);
        yield ConstantNumber(n);
        break;
      case 'input':
        assert(parts.moveNext());
        String desc = parts.current;
        yield FromUser(desc);
        break;
    }
  }
}
