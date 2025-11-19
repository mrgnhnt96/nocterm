import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart' as xterm;
import 'package:xterm/ui.dart' as xterm_flutter;
import 'package:nocterm/nocterm.dart' as nocterm;
import 'src/web_terminal.dart';
import 'src/web_terminal_binding.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const NoctermWebApp());
}

class NoctermWebApp extends StatelessWidget {
  const NoctermWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'nocterm Web Terminal', theme: ThemeData.dark(), home: const TerminalPage());
  }
}

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late xterm.Terminal terminal;
  late WebTerminal noctermBackend;
  late WebTerminalBinding binding;

  @override
  void initState() {
    super.initState();

    // Create xterm terminal
    terminal = xterm.Terminal(maxLines: 1000);

    // Defer nocterm initialization until after first frame
    // when TerminalView has set the correct terminal size
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _initializeNocterm();
    });
  }

  void _initializeNocterm() {
    // Create nocterm backend that writes to xterm
    noctermBackend = WebTerminal(
      terminal,
      size: nocterm.Size(terminal.viewWidth.toDouble(), terminal.viewHeight.toDouble()),
    );

    // Initialize nocterm binding
    binding = WebTerminalBinding(noctermBackend, terminal);
    binding.initializeBinding();
    binding.initialize();

    // Run a simple nocterm app
    _runNoctermApp();
  }

  void _runNoctermApp() {
    // Create an interactive demo app
    final app = InteractiveDemo(binding: binding);

    // Attach the app to the binding
    binding.attachRootComponent(app);

    // Schedule initial frame
    binding.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: xterm_flutter.TerminalView(
          terminal,
          textStyle: xterm_flutter.TerminalStyle.fromTextStyle(
            GoogleFonts.jetBrainsMono().copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    binding.shutdown();
    super.dispose();
  }
}

// Interactive Demo App
class InteractiveDemo extends nocterm.StatefulComponent {
  final WebTerminalBinding binding;

  const InteractiveDemo({super.key, required this.binding});

  @override
  nocterm.State<InteractiveDemo> createState() => _InteractiveDemoState();
}

class _InteractiveDemoState extends nocterm.State<InteractiveDemo> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Widgets', 'Animation', 'About'];
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now().toString().substring(11, 19);
    });
  }

  @override
  nocterm.Component build(nocterm.BuildContext context) {
    return nocterm.Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == nocterm.LogicalKey.digit1) {
          setState(() => _selectedTab = 0);
          return true;
        } else if (event.logicalKey == nocterm.LogicalKey.digit2) {
          setState(() => _selectedTab = 1);
          return true;
        } else if (event.logicalKey == nocterm.LogicalKey.digit3) {
          setState(() => _selectedTab = 2);
          return true;
        } else if (event.logicalKey == nocterm.LogicalKey.digit4) {
          setState(() => _selectedTab = 3);
          return true;
        } else if (event.logicalKey == nocterm.LogicalKey.arrowLeft) {
          setState(() {
            _selectedTab = (_selectedTab - 1).clamp(0, _tabs.length - 1);
          });
          return true;
        } else if (event.logicalKey == nocterm.LogicalKey.arrowRight) {
          setState(() {
            _selectedTab = (_selectedTab + 1).clamp(0, _tabs.length - 1);
          });
          return true;
        }
        return false;
      },
      child: nocterm.Container(
        decoration: const nocterm.BoxDecoration(
          color: nocterm.Color(0xFF1A1B26),
        ),
        child: nocterm.Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            nocterm.Expanded(
              child: _buildContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  nocterm.Component _buildHeader() {
    return nocterm.Container(
      decoration: const nocterm.BoxDecoration(
        color: nocterm.Color(0xFF2D2E40),
        border: nocterm.BoxBorder(
          bottom: nocterm.BorderSide(color: nocterm.Color(0xFF565869)),
        ),
      ),
      padding: const nocterm.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: nocterm.Row(
        children: [
          const nocterm.Text(
            '🚀 ',
            style: nocterm.TextStyle(color: nocterm.Colors.cyan),
          ),
          const nocterm.Text(
            'nocterm Web Demo',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.Spacer(),
          nocterm.Text(
            _currentTime,
            style: const nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
          ),
        ],
      ),
    );
  }

  nocterm.Component _buildTabBar() {
    return nocterm.Container(
      decoration: const nocterm.BoxDecoration(
        color: nocterm.Color(0xFF24253A),
      ),
      padding: const nocterm.EdgeInsets.symmetric(horizontal: 1),
      child: nocterm.Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            nocterm.Expanded(
              child: nocterm.Container(
                decoration: nocterm.BoxDecoration(
                  color: i == _selectedTab ? const nocterm.Color(0xFF2D2E40) : null,
                  border: i == _selectedTab
                      ? const nocterm.BoxBorder(
                          bottom: nocterm.BorderSide(
                            color: nocterm.Color(0xFF7AA2F7),
                            width: 2,
                          ),
                        )
                      : null,
                ),
                padding: const nocterm.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: nocterm.Center(
                  child: nocterm.Text(
                    _tabs[i],
                    style: nocterm.TextStyle(
                      color: i == _selectedTab
                          ? const nocterm.Color(0xFF7AA2F7)
                          : const nocterm.Color(0xFF565869),
                      fontWeight: i == _selectedTab ? nocterm.FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  nocterm.Component _buildContent() {
    switch (_selectedTab) {
      case 0:
        return const DashboardTab();
      case 1:
        return const WidgetsTab();
      case 2:
        return const AnimationTab();
      case 3:
        return const AboutTab();
      default:
        return nocterm.Container();
    }
  }

  nocterm.Component _buildFooter() {
    return nocterm.Container(
      decoration: const nocterm.BoxDecoration(
        color: nocterm.Color(0xFF2D2E40),
        border: nocterm.BoxBorder(
          top: nocterm.BorderSide(color: nocterm.Color(0xFF565869)),
        ),
      ),
      padding: const nocterm.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: const nocterm.Row(
        children: [
          nocterm.Text(
            '←→: Switch Tabs',
            style: nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
          ),
          nocterm.Text(' | ', style: nocterm.TextStyle(color: nocterm.Color(0xFF565869))),
          nocterm.Text(
            '1-4: Quick Jump',
            style: nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
          ),
          nocterm.Spacer(),
          nocterm.Text(
            'nocterm v1.0',
            style: nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab with live metrics
class DashboardTab extends nocterm.StatefulComponent {
  const DashboardTab({super.key});

  @override
  nocterm.State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends nocterm.State<DashboardTab> {
  Timer? _timer;
  List<double> _cpuHistory = List.generate(20, (_) => 0.0);
  double _cpu = 0.0;
  double _memory = 0.0;
  double _network = 0.0;
  int _requests = 0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _cpu = 20 + _random.nextDouble() * 60;
        _memory = 40 + _random.nextDouble() * 30;
        _network = 10 + _random.nextDouble() * 50;
        _requests += _random.nextInt(10);
        _cpuHistory = [..._cpuHistory.skip(1), _cpu];
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  nocterm.Component build(nocterm.BuildContext context) {
    return nocterm.Padding(
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        children: [
          nocterm.Row(
            children: [
              nocterm.Expanded(child: _buildStatCard('CPU', '${_cpu.toStringAsFixed(1)}%', nocterm.Colors.cyan)),
              const nocterm.SizedBox(width: 2),
              nocterm.Expanded(child: _buildStatCard('Memory', '${_memory.toStringAsFixed(1)}%', nocterm.Colors.green)),
              const nocterm.SizedBox(width: 2),
              nocterm.Expanded(child: _buildStatCard('Network', '${_network.toStringAsFixed(1)} MB/s', nocterm.Colors.yellow)),
              const nocterm.SizedBox(width: 2),
              nocterm.Expanded(child: _buildStatCard('Requests', '$_requests', nocterm.Colors.magenta)),
            ],
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Expanded(
            child: nocterm.Row(
              children: [
                nocterm.Expanded(
                  flex: 2,
                  child: _buildSystemMonitor(),
                ),
                const nocterm.SizedBox(width: 2),
                nocterm.Expanded(
                  child: _buildActivityFeed(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  nocterm.Component _buildStatCard(String title, String value, nocterm.Color color) {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(1),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          nocterm.Text(
            title,
            style: const nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
          ),
          const nocterm.SizedBox(height: 1),
          nocterm.Text(
            value,
            style: nocterm.TextStyle(
              color: color,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  nocterm.Component _buildSystemMonitor() {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '📊 System Monitor',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          _buildProgressBar('CPU', _cpu, nocterm.Colors.cyan),
          const nocterm.SizedBox(height: 1),
          _buildProgressBar('MEM', _memory, nocterm.Colors.green),
          const nocterm.SizedBox(height: 1),
          _buildProgressBar('NET', _network, nocterm.Colors.yellow),
          const nocterm.SizedBox(height: 2),
          const nocterm.Text(
            'CPU History',
            style: nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
          ),
          const nocterm.SizedBox(height: 1),
          _buildSparkline(),
        ],
      ),
    );
  }

  nocterm.Component _buildProgressBar(String label, double value, nocterm.Color color) {
    final barLength = 20;
    final filledLength = (value / 100 * barLength).round();
    final emptyLength = barLength - filledLength;

    return nocterm.Row(
      children: [
        nocterm.SizedBox(
          width: 4,
          child: nocterm.Text(
            label,
            style: const nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
          ),
        ),
        nocterm.Text(
          '█' * filledLength,
          style: nocterm.TextStyle(color: color),
        ),
        nocterm.Text(
          '░' * emptyLength,
          style: const nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
        ),
        const nocterm.SizedBox(width: 1),
        nocterm.Text(
          '${value.toStringAsFixed(0)}%',
          style: nocterm.TextStyle(color: color),
        ),
      ],
    );
  }

  nocterm.Component _buildSparkline() {
    String sparkline = '';
    const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    for (double value in _cpuHistory) {
      int index = ((value / 100) * (chars.length - 1)).round();
      sparkline += chars[index];
    }
    return nocterm.Text(
      sparkline,
      style: const nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
    );
  }

  nocterm.Component _buildActivityFeed() {
    final activities = [
      ('🟢', 'User login', '2m'),
      ('🔵', 'API call', '5m'),
      ('🟡', 'DB query', '8m'),
      ('🟢', 'Cache hit', '12m'),
      ('🔴', 'Error', '15m'),
      ('🟢', 'Deploy', '1h'),
    ];

    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '📝 Activity',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Expanded(
            child: nocterm.Column(
              children: [
                for (var activity in activities)
                  nocterm.Padding(
                    padding: const nocterm.EdgeInsets.only(bottom: 1),
                    child: nocterm.Row(
                      children: [
                        nocterm.Text(activity.$1),
                        const nocterm.SizedBox(width: 1),
                        nocterm.Expanded(
                          child: nocterm.Text(
                            activity.$2,
                            style: const nocterm.TextStyle(color: nocterm.Colors.white),
                          ),
                        ),
                        nocterm.Text(
                          activity.$3,
                          style: const nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widgets Tab showcasing different components
class WidgetsTab extends nocterm.StatefulComponent {
  const WidgetsTab({super.key});

  @override
  nocterm.State<WidgetsTab> createState() => _WidgetsTabState();
}

class _WidgetsTabState extends nocterm.State<WidgetsTab> {
  int _counter = 0;
  int _selectedItem = 0;
  bool _toggleOn = false;
  final List<String> _items = ['Option A', 'Option B', 'Option C', 'Option D'];

  @override
  nocterm.Component build(nocterm.BuildContext context) {
    return nocterm.Padding(
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Row(
        children: [
          nocterm.Expanded(child: _buildCounterDemo()),
          const nocterm.SizedBox(width: 2),
          nocterm.Expanded(child: _buildSelectionDemo()),
          const nocterm.SizedBox(width: 2),
          nocterm.Expanded(child: _buildStylesDemo()),
        ],
      ),
    );
  }

  nocterm.Component _buildCounterDemo() {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.center,
        children: [
          const nocterm.Text(
            '🔢 Counter',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Text(
            '$_counter',
            style: const nocterm.TextStyle(
              color: nocterm.Color(0xFF7AA2F7),
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Row(
            mainAxisAlignment: nocterm.MainAxisAlignment.center,
            children: [
              nocterm.GestureDetector(
                onTap: () => setState(() => _counter--),
                child: nocterm.Container(
                  decoration: const nocterm.BoxDecoration(
                    color: nocterm.Color(0xFF565869),
                  ),
                  padding: const nocterm.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: const nocterm.Text('-', style: nocterm.TextStyle(color: nocterm.Colors.white)),
                ),
              ),
              const nocterm.SizedBox(width: 2),
              nocterm.GestureDetector(
                onTap: () => setState(() => _counter++),
                child: nocterm.Container(
                  decoration: const nocterm.BoxDecoration(
                    color: nocterm.Color(0xFF7AA2F7),
                  ),
                  padding: const nocterm.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: const nocterm.Text('+', style: nocterm.TextStyle(color: nocterm.Color(0xFF1A1B26))),
                ),
              ),
            ],
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Row(
            mainAxisAlignment: nocterm.MainAxisAlignment.center,
            children: [
              nocterm.GestureDetector(
                onTap: () => setState(() => _toggleOn = !_toggleOn),
                child: nocterm.Text(
                  _toggleOn ? '◉ ON ' : '○ OFF',
                  style: nocterm.TextStyle(
                    color: _toggleOn ? nocterm.Colors.green : nocterm.Color(0xFF565869),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  nocterm.Component _buildSelectionDemo() {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '📋 Selection',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          for (int i = 0; i < _items.length; i++)
            nocterm.GestureDetector(
              onTap: () => setState(() => _selectedItem = i),
              child: nocterm.Padding(
                padding: const nocterm.EdgeInsets.only(bottom: 1),
                child: nocterm.Row(
                  children: [
                    nocterm.Text(
                      _selectedItem == i ? '▶ ' : '  ',
                      style: const nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
                    ),
                    nocterm.Container(
                      decoration: nocterm.BoxDecoration(
                        color: _selectedItem == i
                            ? const nocterm.Color(0xFF2D2E40)
                            : null,
                      ),
                      padding: const nocterm.EdgeInsets.symmetric(horizontal: 1),
                      child: nocterm.Text(
                        _items[i],
                        style: nocterm.TextStyle(
                          color: _selectedItem == i
                              ? const nocterm.Color(0xFF7AA2F7)
                              : nocterm.Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  nocterm.Component _buildStylesDemo() {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: const nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          nocterm.Text(
            '🎨 Text Styles',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          nocterm.SizedBox(height: 2),
          nocterm.Text(
            'Bold text',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          nocterm.Text(
            'Italic text',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontStyle: nocterm.FontStyle.italic,
            ),
          ),
          nocterm.Text(
            'Underlined',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              decoration: nocterm.TextDecoration.underline,
            ),
          ),
          nocterm.Text(
            'Dim text',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.dim,
            ),
          ),
          nocterm.SizedBox(height: 1),
          nocterm.Text(
            'Cyan',
            style: nocterm.TextStyle(color: nocterm.Colors.cyan),
          ),
          nocterm.Text(
            'Green',
            style: nocterm.TextStyle(color: nocterm.Colors.green),
          ),
          nocterm.Text(
            'Yellow',
            style: nocterm.TextStyle(color: nocterm.Colors.yellow),
          ),
          nocterm.Text(
            'Magenta',
            style: nocterm.TextStyle(color: nocterm.Colors.magenta),
          ),
        ],
      ),
    );
  }
}

// Animation Tab with animated elements
class AnimationTab extends nocterm.StatefulComponent {
  const AnimationTab({super.key});

  @override
  nocterm.State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends nocterm.State<AnimationTab> {
  Timer? _timer;
  int _frame = 0;
  int _spinnerFrame = 0;
  double _progressValue = 0.0;
  int _waveOffset = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _frame++;
        _spinnerFrame = (_spinnerFrame + 1) % 8;
        _progressValue = (_progressValue + 0.01) % 1.0;
        _waveOffset = (_waveOffset + 1) % 20;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  nocterm.Component build(nocterm.BuildContext context) {
    return nocterm.Padding(
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        children: [
          nocterm.Row(
            children: [
              nocterm.Expanded(child: _buildSpinnerDemo()),
              const nocterm.SizedBox(width: 2),
              nocterm.Expanded(child: _buildProgressDemo()),
            ],
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Expanded(child: _buildWaveDemo()),
        ],
      ),
    );
  }

  nocterm.Component _buildSpinnerDemo() {
    const spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧'];
    const altSpinners = ['◐', '◓', '◑', '◒'];
    const barSpinners = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '🔄 Spinners',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Row(
            children: [
              nocterm.Text(
                spinnerChars[_spinnerFrame],
                style: const nocterm.TextStyle(color: nocterm.Colors.cyan),
              ),
              const nocterm.SizedBox(width: 2),
              const nocterm.Text(
                'Loading...',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
            ],
          ),
          const nocterm.SizedBox(height: 1),
          nocterm.Row(
            children: [
              nocterm.Text(
                altSpinners[_spinnerFrame % 4],
                style: const nocterm.TextStyle(color: nocterm.Colors.green),
              ),
              const nocterm.SizedBox(width: 2),
              const nocterm.Text(
                'Processing...',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
            ],
          ),
          const nocterm.SizedBox(height: 1),
          nocterm.Row(
            children: [
              nocterm.Text(
                barSpinners[_spinnerFrame],
                style: const nocterm.TextStyle(color: nocterm.Colors.yellow),
              ),
              const nocterm.SizedBox(width: 2),
              const nocterm.Text(
                'Building...',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  nocterm.Component _buildProgressDemo() {
    final barLength = 20;
    final filledLength = (_progressValue * barLength).round();
    final emptyLength = barLength - filledLength;

    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '📊 Progress',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          nocterm.Row(
            children: [
              nocterm.Text(
                '█' * filledLength,
                style: const nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
              ),
              nocterm.Text(
                '░' * emptyLength,
                style: const nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
              ),
              nocterm.Text(
                ' ${(_progressValue * 100).toStringAsFixed(0)}%',
                style: const nocterm.TextStyle(color: nocterm.Colors.white),
              ),
            ],
          ),
          const nocterm.SizedBox(height: 2),
          // Bouncing progress
          _buildBouncingProgress(),
        ],
      ),
    );
  }

  nocterm.Component _buildBouncingProgress() {
    final barLength = 20;
    final position = (_frame ~/ 3) % (barLength * 2);
    final actualPos = position < barLength ? position : (barLength * 2 - position - 1);

    String bar = '';
    for (int i = 0; i < barLength; i++) {
      if (i == actualPos) {
        bar += '●';
      } else {
        bar += '─';
      }
    }

    return nocterm.Text(
      '[$bar]',
      style: const nocterm.TextStyle(color: nocterm.Colors.green),
    );
  }

  nocterm.Component _buildWaveDemo() {
    return nocterm.Container(
      decoration: nocterm.BoxDecoration(
        color: const nocterm.Color(0xFF24253A),
        border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF565869)),
      ),
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Column(
        crossAxisAlignment: nocterm.CrossAxisAlignment.start,
        children: [
          const nocterm.Text(
            '🌊 Wave Animation',
            style: nocterm.TextStyle(
              color: nocterm.Colors.white,
              fontWeight: nocterm.FontWeight.bold,
            ),
          ),
          const nocterm.SizedBox(height: 2),
          _buildWave(),
          const nocterm.SizedBox(height: 1),
          _buildColorGradient(),
        ],
      ),
    );
  }

  nocterm.Component _buildWave() {
    const waveChars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    String wave = '';
    for (int i = 0; i < 40; i++) {
      final value = ((math.sin((i + _waveOffset) * 0.3) + 1) / 2 * (waveChars.length - 1)).round();
      wave += waveChars[value];
    }
    return nocterm.Text(
      wave,
      style: const nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
    );
  }

  nocterm.Component _buildColorGradient() {
    return nocterm.Row(
      children: [
        for (int i = 0; i < 40; i++)
          nocterm.Text(
            '█',
            style: nocterm.TextStyle(
              color: nocterm.Color.fromRGB(
                ((i + _waveOffset) * 6 % 256).round(),
                ((40 - i + _waveOffset) * 6 % 256).round(),
                200,
              ),
            ),
          ),
      ],
    );
  }
}

// About Tab
class AboutTab extends nocterm.StatelessComponent {
  const AboutTab({super.key});

  @override
  nocterm.Component build(nocterm.BuildContext context) {
    return nocterm.Padding(
      padding: const nocterm.EdgeInsets.all(2),
      child: nocterm.Center(
        child: nocterm.Container(
          decoration: nocterm.BoxDecoration(
            color: const nocterm.Color(0xFF24253A),
            border: nocterm.BoxBorder.all(color: const nocterm.Color(0xFF7AA2F7), width: 2),
          ),
          padding: const nocterm.EdgeInsets.all(3),
          child: const nocterm.Column(
            mainAxisSize: nocterm.MainAxisSize.min,
            children: [
              nocterm.Text(
                '╔═══════════════════════════════════╗',
                style: nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
              ),
              nocterm.Text(
                '║   🚀 NOCTERM WEB TERMINAL DEMO    ║',
                style: nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
              ),
              nocterm.Text(
                '╚═══════════════════════════════════╝',
                style: nocterm.TextStyle(color: nocterm.Color(0xFF7AA2F7)),
              ),
              nocterm.SizedBox(height: 2),
              nocterm.Text(
                'A powerful Terminal User Interface',
                style: nocterm.TextStyle(
                  color: nocterm.Colors.white,
                  fontWeight: nocterm.FontWeight.bold,
                ),
              ),
              nocterm.Text(
                'running in your browser!',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.SizedBox(height: 2),
              nocterm.Text(
                '✨ Features',
                style: nocterm.TextStyle(
                  color: nocterm.Color(0xFF7AA2F7),
                  fontWeight: nocterm.FontWeight.bold,
                ),
              ),
              nocterm.SizedBox(height: 1),
              nocterm.Text(
                '• Flutter-like component system',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.Text(
                '• Reactive state management',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.Text(
                '• Rich text and color support',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.Text(
                '• Mouse and keyboard input',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.Text(
                '• Animations and timers',
                style: nocterm.TextStyle(color: nocterm.Colors.white),
              ),
              nocterm.SizedBox(height: 2),
              nocterm.Text(
                '🛠️ Built with Dart',
                style: nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
              ),
              nocterm.Text(
                '💙 Powered by nocterm',
                style: nocterm.TextStyle(color: nocterm.Color(0xFF565869)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
