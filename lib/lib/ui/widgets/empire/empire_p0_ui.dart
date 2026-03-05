// lib/ui/widgets/empire/empire_p0_ui.dart
//
// P0 UI features for Empire Screen (Galactic Industrial Empire)
// - Industry cycle progress bars (smooth, no full-list rebuild per tick)
// - Buy multiplier segmented control (x1/x10/x25/Max) + shared selection
// - Button affordability highlight + micro-juice (purchase flash, claim pulse)
//
// Designed to integrate with existing EmpireScreen + IndustryTile components.
// This file does NOT add new game systems; it adds UI helpers + minimal engine getter expectations.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ---------------------------------------------------------------------------
/// BUY MULTIPLIER
/// ---------------------------------------------------------------------------

enum BuyMultiplier {
  x1,
  x10,
  x25,
  max,
}

extension BuyMultiplierX on BuyMultiplier {
  String get label {
    switch (this) {
      case BuyMultiplier.x1:
        return 'Buy x1';
      case BuyMultiplier.x10:
        return 'Buy x10';
      case BuyMultiplier.x25:
        return 'Buy x25';
      case BuyMultiplier.max:
        return 'Max';
    }
  }

  int? get fixedCount {
    switch (this) {
      case BuyMultiplier.x1:
        return 1;
      case BuyMultiplier.x10:
        return 10;
      case BuyMultiplier.x25:
        return 25;
      case BuyMultiplier.max:
        return null; // indicates "max"
    }
  }
}

/// Controller that can be owned by EmpireScreen and passed down via scope.
class BuyMultiplierController extends ValueNotifier<BuyMultiplier> {
  BuyMultiplierController([BuyMultiplier initial = BuyMultiplier.x1]) : super(initial);

  void set(BuyMultiplier m) => value = m;
}

class BuyMultiplierScope extends InheritedNotifier<BuyMultiplierController> {
  const BuyMultiplierScope({
    super.key,
    required BuyMultiplierController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static BuyMultiplierController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BuyMultiplierScope>();
    assert(scope != null, 'BuyMultiplierScope not found in widget tree');
    return scope!.notifier!;
  }
}

/// Segmented control (Material 3) to pick buy multiplier.
class BuyMultiplierSegmentedControl extends StatelessWidget {
  final BuyMultiplierController controller;

  const BuyMultiplierSegmentedControl({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BuyMultiplier>(
      valueListenable: controller,
      builder: (context, selected, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SegmentedButton<BuyMultiplier>(
            segments: const <ButtonSegment<BuyMultiplier>>[
              ButtonSegment(value: BuyMultiplier.x1, label: Text('Buy x1')),
              ButtonSegment(value: BuyMultiplier.x10, label: Text('Buy x10')),
              ButtonSegment(value: BuyMultiplier.x25, label: Text('Buy x25')),
              ButtonSegment(value: BuyMultiplier.max, label: Text('Max')),
            ],
            selected: <BuyMultiplier>{selected},
            onSelectionChanged: (set) {
              if (set.isEmpty) return;
              controller.set(set.first);
            },
            showSelectedIcon: false,
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// INDUSTRY CYCLE PROGRESS BAR
/// ---------------------------------------------------------------------------
/// Each IndustryTile hosts its own ticker that repaints only the bar.
/// Keep engine integration read-only.
///
/// Minimal engine expectations (getters):
/// - double getIndustryCycleProgress01(String industryId)   // 0..1 (clamped)
/// - bool isIndustryProducing(String industryId)            // false => show 0 or paused state
abstract class IndustryProgressProvider {
  double getCycleProgress01(String industryId);
  bool isProducing(String industryId);

  /// Optional: display text for remaining time (e.g. "2.3s")
  String? getEtaText(String industryId) => null;
}

class IndustryCycleProgressBar extends StatefulWidget {
  final String industryId;
  final IndustryProgressProvider provider;

  /// If true, show a tiny ETA label on the right (uses provider.getEtaText).
  final bool showEta;

  const IndustryCycleProgressBar({
    super.key,
    required this.industryId,
    required this.provider,
    this.showEta = false,
  });

  @override
  State<IndustryCycleProgressBar> createState() => _IndustryCycleProgressBarState();
}

class _IndustryCycleProgressBarState extends State<IndustryCycleProgressBar> {
  double _progress = 0;

  // throttle updates (~30fps)
  static const Duration _frame = Duration(milliseconds: 33);
  Duration _last = Duration.zero;

  double _readProgress() {
    if (!widget.provider.isProducing(widget.industryId)) return 0;
    final p = widget.provider.getCycleProgress01(widget.industryId);
    return p.isNaN ? 0 : p.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _progress = _readProgress();
    SchedulerBinding.instance.addPostFrameCallback((_) => _tickLoop());
  }

  Future<void> _tickLoop() async {
    while (mounted) {
      await Future<void>.delayed(_frame);
      final next = _readProgress();
      if ((next - _progress).abs() < 0.003) continue;
      setState(() => _progress = next);
    }
  }

  @override
  void didUpdateWidget(covariant IndustryCycleProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.industryId != widget.industryId || oldWidget.provider != widget.provider) {
      _progress = _readProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eta = widget.showEta ? widget.provider.getEtaText(widget.industryId) : null;

    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: _progress),
              builder: (context, v, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: v,
                      backgroundColor: cs.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      minHeight: 8,
                    ),
                  ),
                );
              },
            ),
          ),
          if (eta != null && eta.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              eta,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// AFFORDABILITY HIGHLIGHT + MICRO-JUICE
/// ---------------------------------------------------------------------------

/// Wrap an action button to:
/// - highlight when affordable
/// - flash briefly when purchase succeeds (trigger via [flashToken] changes)
class AffordableActionButton extends StatefulWidget {
  final bool isAffordable;
  final int flashToken;

  final VoidCallback? onPressed;
  final Widget child;

  final ButtonStyle? style;
  final bool tonal;

  const AffordableActionButton({
    super.key,
    required this.isAffordable,
    required this.flashToken,
    required this.onPressed,
    required this.child,
    this.style,
    this.tonal = true,
  });

  @override
  State<AffordableActionButton> createState() => _AffordableActionButtonState();
}

class _AffordableActionButtonState extends State<AffordableActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  late final Animation<double> _flashT;

  int _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _lastToken = widget.flashToken;
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _flashT = CurvedAnimation(parent: _flash, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant AffordableActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashToken != _lastToken) {
      _lastToken = widget.flashToken;
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final canPress = widget.onPressed != null;
    final isAffordable = widget.isAffordable && canPress;

    final ringColor =
        isAffordable ? cs.primary.withOpacity(0.65) : cs.outlineVariant.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _flashT,
      builder: (context, child) {
        final overlay =
            Color.lerp(Colors.transparent, cs.primary.withOpacity(0.22), _flashT.value);

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ringColor, width: isAffordable ? 1.5 : 1),
            color: overlay,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: child,
          ),
        );
      },
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (widget.tonal) {
      return FilledButton.tonal(
        onPressed: widget.onPressed,
        style: widget.style ??
            FilledButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
        child: widget.child,
      );
    }
    return FilledButton(
      onPressed: widget.onPressed,
      style: widget.style,
      child: widget.child,
    );
  }
}

/// Pulsing wrapper for claimable actions (offline claim, contract claim).
/// Only animates when [enabled] is true.
class ClaimPulse extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const ClaimPulse({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  State<ClaimPulse> createState() => _ClaimPulseState();
}

class _ClaimPulseState extends State<ClaimPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ClaimPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final scale = 1.0 + (t * 0.03);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
