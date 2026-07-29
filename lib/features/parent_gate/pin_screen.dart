import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../parent_dashboard/parent_dashboard_screen.dart';
import '../settings/settings_controller.dart';

/// Simple numeric parent PIN screen (second barrier of the parent gate).
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _entered = '';
  bool _wrong = false;

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _wrong = false;
    });
    if (_entered.length == 4) _check();
  }

  void _check() {
    final settings = context.read<SettingsController>();
    if (settings.checkPin(_entered)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const ParentDashboardScreen(),
        ),
      );
    } else {
      setState(() {
        _entered = '';
        _wrong = true;
      });
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usesDefaultPin =
        context.watch<SettingsController>().settings.usesDefaultPin;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentGateTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.pinEnterTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (usesDefaultPin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      l10n.pinDefaultHint(AppConfig.defaultParentPin),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_wrong)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.pinIncorrect,
                      style: const TextStyle(color: Palette.textSoft),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _entered.length
                              ? Palette.coral
                              : Palette.disabled,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace});

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap}) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 76,
          height: 64,
          child: FilledButton.tonal(
            onPressed: onTap ?? () => onDigit(label),
            child: Text(label, style: const TextStyle(fontSize: 24)),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 88),
            key('0'),
            Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 76,
                height: 64,
                child: IconButton.filledTonal(
                  onPressed: onBackspace,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
