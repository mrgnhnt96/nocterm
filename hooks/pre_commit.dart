import 'package:hooksman/hooksman.dart';

Hook main() {
  return PreCommitHook(tasks: [
    ReRegisterHooks(),
    ShellTask(
        include: [Glob('**/*.dart')],
        commands: (files) => ['dart format ${files.join(' ')}'])
  ]);
}
