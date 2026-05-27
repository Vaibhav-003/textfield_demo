import 'package:flutter/material.dart';
import 'package:textfield_demo/bandwidth_checker.dart';

import 'accessible_search_field.dart';
import 'nominee_screen.dart';
import 'signal_strength_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessible Search Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SearchDemoPage(),
    );
  }
}

class SearchDemoPage extends StatefulWidget {
  const SearchDemoPage({super.key});

  @override
  State<SearchDemoPage> createState() => _SearchDemoPageState();
}

class _SearchDemoPageState extends State<SearchDemoPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: AccessibleSearchField(
          hintText: 'Search anything…',
          autofocus: true,
          onBackPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Back pressed')));
          },
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: (value) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Searching for: "$value"')));
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Type something to search'
                    : 'Current query: "$_searchQuery"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _isNumeric(_searchQuery)
                      ? 'TalkBack will read digits individually: ${_searchQuery.split('').join(', ')}'
                      : 'TalkBack will read text normally',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  print('Checking bandwidth...');
                  final info = await BandwidthChecker.instance.check();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Network Quality'),
                      content: Text(
                        '${info?.quality.name.toUpperCase()} connection\n'
                        'Speed: ${info?.downloadSpeedKbps.toStringAsFixed(1)} kbps\n'
                        'Latency: ${info?.latencyMs} ms\n'
                        'Type: ${info?.connectionType}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Check Bandwidth'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignalStrengthScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.signal_cellular_alt),
                label: const Text('Signal Strength'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NomineeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Manage Nominees'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNumeric(String s) {
    if (s.isEmpty) return false;
    return s.runes.every((r) => r >= 48 && r <= 57);
  }
}
