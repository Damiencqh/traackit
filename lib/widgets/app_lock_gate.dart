import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../state/app_state.dart';

/// Wraps the whole app. When the lock pref is on, it covers everything with
/// an opaque lock screen and requires Face ID / passcode — on cold start and
/// whenever the app returns from the background.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer to after first frame so prefs have loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockOnStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _lockEnabled =>
      ref.read(userPrefsProvider).value?.lockEnabled ?? false;

  Future<void> _lockOnStart() async {
    if (_lockEnabled) {
      setState(() => _locked = true);
      _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled) return;
    if (state == AppLifecycleState.paused) {
      // Fully backgrounded — lock so it's protected on return.
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed) {
      if (_locked && !_authenticating) _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    _authenticating = true;
    final ok = await ref.read(authServiceProvider).authenticate();
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked) _LockScreen(onUnlock: _authenticate),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: AppColors.paper, // opaque — hides everything behind it
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 46, color: AppColors.accent),
                const SizedBox(height: 20),
                Text('Traackit is locked', style: AppText.serifBody(size: 20)),
                const SizedBox(height: 8),
                Text('Authenticate to continue',
                    style: AppText.ui(size: 13, color: AppColors.inkMuted)),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                  ),
                  onPressed: onUnlock,
                  child: Text('UNLOCK',
                      style: AppText.ui(
                          size: 12,
                          color: AppColors.paper,
                          weight: FontWeight.w600,
                          letterSpacing: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
