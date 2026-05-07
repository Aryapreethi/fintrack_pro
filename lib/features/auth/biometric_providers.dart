import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Tracks whether the user has authenticated this app session.
class BiometricGateState extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

final biometricGateStateProvider =
    NotifierProvider<BiometricGateState, bool>(BiometricGateState.new);
