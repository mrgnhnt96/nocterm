import 'package:xterm/xterm.dart' as xterm;
import 'package:nocterm/nocterm.dart';

/// Terminal that writes output to an xterm.js instance in the browser.
/// Used for web mode where the app renders into an HTML canvas instead of stdout.
class WebTerminal extends Terminal {
  final xterm.Terminal xterminal;
  bool _altScreenEnabled = false;
  final StringBuffer _writeBuffer = StringBuffer();

  // ANSI escape codes
  static const _alternateBuffer = '\x1b[?1049h';
  static const _mainBuffer = '\x1b[?1049l';
  static const _showCursor = '\x1b[?25h';

  WebTerminal(this.xterminal, {super.size});

  @override
  void write(String text) {
    _writeBuffer.write(text);
  }

  @override
  void flush() {
    if (_writeBuffer.isNotEmpty) {
      final bufferContent = _writeBuffer.toString();
      xterminal.write(bufferContent);
      _writeBuffer.clear();
    }
  }

  @override
  void enterAlternateScreen() {
    if (!_altScreenEnabled) {
      flush();
      xterminal.write(_alternateBuffer);
      clear();
      _altScreenEnabled = true;
    }
  }

  @override
  void leaveAlternateScreen() {
    if (_altScreenEnabled) {
      flush();
      xterminal.write(_mainBuffer);
      _altScreenEnabled = false;
    }
  }

  @override
  void showCursor() {
    flush();
    xterminal.write(_showCursor);
  }
}
