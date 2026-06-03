import 'package:flutter/material.dart';
import 'signal_checker.dart';

class SignalStrengthScreen extends StatefulWidget {
  const SignalStrengthScreen({super.key});

  @override
  State<SignalStrengthScreen> createState() => _SignalStrengthScreenState();
}

class _SignalStrengthScreenState extends State<SignalStrengthScreen> {
  final List<_SignalReading> _readings = [];
  bool _isLoading = false;

  Future<void> _fetchSignal() async {
    setState(() => _isLoading = true);
    final info = await SignalChecker.instance.check();
    setState(() {
      _isLoading = false;
      _readings.insert(
        0,
        _SignalReading(
          connectionType: info?.connectionType,
          level: info?.signalStrength,
          time: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signal Strength'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _fetchSignal,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.signal_cellular_alt),
        label: Text(_isLoading ? 'Checking...' : 'Check Signal'),
      ),
      body: _readings.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the button to fetch signal strength',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 96,
              ),
              itemCount: _readings.length,
              itemBuilder: (context, index) {
                final r = _readings[index];
                final timeStr =
                    '${r.time.hour.toString().padLeft(2, '0')}:'
                    '${r.time.minute.toString().padLeft(2, '0')}:'
                    '${r.time.second.toString().padLeft(2, '0')}';

                final connTypeStr = r.connectionType != null
                    ? r.connectionType!.toUpperCase()
                    : 'NO CONNECTION';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: _signalIcon(r.level, colorScheme),
                    title: Text(
                      r.level != null
                          ? '${_levelLabel(r.level!)}  (${r.level}/4)'
                          : 'Unavailable',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text('$connTypeStr • $timeStr'),
                  ),
                );
              },
            ),
    );
  }

  Widget _signalIcon(int? level, ColorScheme cs) {
    if (level == null) {
      return Icon(Icons.signal_cellular_off, size: 32, color: cs.outlineVariant);
    }

    final color = switch (level) {
      4 => Colors.green,
      3 => Colors.lightGreen,
      2 => Colors.orange,
      1 => Colors.deepOrange,
      0 => Colors.red,
      _ => cs.outlineVariant,
    };
    final icon = switch (level) {
      >= 3 => Icons.signal_cellular_alt,
      2 => Icons.signal_cellular_alt_2_bar,
      1 => Icons.signal_cellular_alt_1_bar,
      0 => Icons.signal_cellular_0_bar,
      _ => Icons.signal_cellular_off,
    };

    return Icon(icon, size: 32, color: color);
  }

  String _levelLabel(int level) => switch (level) {
    0 => 'None',
    1 => 'Poor',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Excellent',
    _ => 'Unknown',
  };
}

class _SignalReading {
  final String? connectionType;
  final int? level;
  final DateTime time;
  const _SignalReading({
    required this.connectionType,
    required this.level,
    required this.time,
  });
}
