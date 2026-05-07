import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/settings_providers.dart';
import 'biometric_providers.dart';

class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  bool _attempting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Re-lock when leaving the app, only if biometric is enabled.
      final enabled = ref.read(settingsProvider).biometricEnabled;
      if (enabled) ref.read(biometricGateStateProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      _maybePrompt();
    }
  }

  Future<void> _maybePrompt() async {
    if (_attempting) return;
    final enabled = ref.read(settingsProvider).biometricEnabled;
    final unlocked = ref.read(biometricGateStateProvider);
    if (!enabled || unlocked) return;
    _attempting = true;
    final svc = ref.read(biometricServiceProvider);
    final available = await svc.isAvailable();
    if (!mounted) {
      _attempting = false;
      return;
    }
    if (!available) {
      // Device doesn't support biometric — auto-unlock to avoid lockout.
      ref.read(biometricGateStateProvider.notifier).unlock();
      _attempting = false;
      return;
    }
    final ok = await svc.authenticate(
      reason: AppLocalizations.of(context).biometricPrompt,
    );
    _attempting = false;
    if (!mounted) return;
    if (ok) {
      ref.read(biometricGateStateProvider.notifier).unlock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(settingsProvider).biometricEnabled;
    final unlocked = ref.watch(biometricGateStateProvider);

    if (!enabled || unlocked) {
      return widget.child;
    }

    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 56,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.biometricPrompt,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _maybePrompt,
                icon: const Icon(Icons.lock_open),
                label: Text(l.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
