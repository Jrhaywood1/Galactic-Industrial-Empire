// lib/ui/widgets/empire/empire_ui_components.dart
//
// Reusable UI components for the Empire Screen (Galactic Industrial Empire).
// - Mobile-first
// - List/sliver friendly (no internal scrolling; lightweight; const-friendly)
// - Designed for up to ~20 industries
//
// NOTE: These widgets are UI-only. They accept data + callbacks from GameEngine/Controllers.
// Do not place business logic here.

import 'package:flutter/material.dart';

/// Visual state indicators for IndustryTile.
enum IndustryVisualState {
  normal,
  starved,
  capped,
  boosted,
}

/// Lightweight, serializable-ish data objects for UI binding.
/// You can replace these with your engine models later; the widgets only need these fields.
@immutable
class CurrencyValue {
  final String label; // e.g. "Credits"
  final String value; // pre-formatted text, e.g. "12.4K"
  final IconData icon;

  const CurrencyValue({
    required this.label,
    required this.value,
    required this.icon,
  });
}

@immutable
class ResourceLineItem {
  final String name; // e.g. "Metal"
  final String amount; // e.g. "12/s" or "500"
  final IconData icon;

  const ResourceLineItem({
    required this.name,
    required this.amount,
    required this.icon,
  });
}

@immutable
class IndustryTileData {
  final String id; // stable key
  final String name;
  final IconData icon;

  // Output
  final String outputResourceName;
  final IconData outputIcon;
  final String productionRateText; // e.g. "12.3/s"

  // Storage
  final double storageFill01; // 0..1
  final String storageText; // e.g. "78%"

  // Upgrade / level
  final int level;
  final String upgradeCostText; // formatted, e.g. "2.4K"
  final bool canUpgrade;

  // Manager
  final bool hasManager;
  final bool canAssignManager;

  // Expanded info
  final List<ResourceLineItem> inputs; // input resources required
  final List<String> multipliers; // e.g. ["x2 Manager", "x1.5 Boost"]

  // Visual state
  final IndustryVisualState state;

  const IndustryTileData({
    required this.id,
    required this.name,
    required this.icon,
    required this.outputResourceName,
    required this.outputIcon,
    required this.productionRateText,
    required this.storageFill01,
    required this.storageText,
    required this.level,
    required this.upgradeCostText,
    required this.canUpgrade,
    required this.hasManager,
    required this.canAssignManager,
    required this.inputs,
    required this.multipliers,
    required this.state,
  });
}

@immutable
class ContractRibbonData {
  final String title; // e.g. "Deliver 500 Metal"
  final String progressText; // e.g. "320/500"
  final double progress01; // 0..1
  final bool isCompleted;

  const ContractRibbonData({
    required this.title,
    required this.progressText,
    required this.progress01,
    required this.isCompleted,
  });
}

/// ----------------------------
/// 1) TopBar
/// ----------------------------
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final CurrencyValue credits;
  final CurrencyValue research;

  /// Optional: show rare materials when provided.
  final CurrencyValue? rareMaterials;

  /// Hidden until unlocked
  final bool showPrestige;
  final String? prestigeText; // e.g. "Ship 2/10" or "Prestige 3"

  final VoidCallback onSettings;

  /// Optional: tap handlers if you want to open currency detail modals.
  final VoidCallback? onTapCredits;
  final VoidCallback? onTapResearch;
  final VoidCallback? onTapRare;
  final VoidCallback? onTapPrestige;

  const TopBar({
    super.key,
    required this.credits,
    required this.research,
    required this.onSettings,
    this.rareMaterials,
    this.showPrestige = false,
    this.prestigeText,
    this.onTapCredits,
    this.onTapResearch,
    this.onTapRare,
    this.onTapPrestige,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _CurrencyPill(
                          data: credits,
                          onTap: onTapCredits,
                        ),
                        const SizedBox(width: 8),
                        _CurrencyPill(
                          data: research,
                          onTap: onTapResearch,
                        ),
                        if (rareMaterials != null) ...[
                          const SizedBox(width: 8),
                          _CurrencyPill(
                            data: rareMaterials!,
                            onTap: onTapRare,
                          ),
                        ],
                        if (showPrestige && (prestigeText?.isNotEmpty ?? false)) ...[
                          const SizedBox(width: 8),
                          _ChipPill(
                            icon: Icons.rocket_launch_rounded,
                            text: prestigeText!,
                            onTap: onTapPrestige,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final CurrencyValue data;
  final VoidCallback? onTap;

  const _CurrencyPill({
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChipPill(
      icon: data.icon,
      text: data.value,
      tooltip: data.label,
      onTap: onTap,
    );
  }
}

class _ChipPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? tooltip;
  final VoidCallback? onTap;

  const _ChipPill({
    required this.icon,
    required this.text,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );

    final wrapped = (onTap == null)
        ? child
        : InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: child,
          );

    if (tooltip == null || tooltip!.isEmpty) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}

/// ----------------------------
/// 2) StatusStrip
/// ----------------------------
class StatusStrip extends StatelessWidget {
  final String netProductionText; // e.g. "Net: 1.24K / sec"
  final IconData netProductionIcon;

  /// Conditional offline claim
  final bool showOfflineClaim;
  final String offlineClaimText; // e.g. "Claim 12.3K"
  final VoidCallback? onOfflineClaim;

  /// Storage warning chip when nearing capacity (provided by caller)
  final bool showStorageWarning;
  final String storageWarningText; // e.g. "Storage Nearly Full"
  final VoidCallback? onStorageWarningTap;

  const StatusStrip({
    super.key,
    required this.netProductionText,
    this.netProductionIcon = Icons.trending_up_rounded,
    this.showOfflineClaim = false,
    this.offlineClaimText = 'Claim',
    this.onOfflineClaim,
    this.showStorageWarning = false,
    this.storageWarningText = 'Storage Near Capacity',
    this.onStorageWarningTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: _InlineStat(
                icon: netProductionIcon,
                text: netProductionText,
              ),
            ),
            if (showStorageWarning) ...[
              const SizedBox(width: 8),
              _WarningChip(
                text: storageWarningText,
                onTap: onStorageWarningTap,
              ),
            ],
            if (showOfflineClaim) ...[
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.download_done_rounded,
                label: offlineClaimText,
                onTap: onOfflineClaim,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineStat({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _WarningChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _WarningChip({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.error.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: cs.onErrorContainer),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );

    return (onTap == null)
        ? chip
        : InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: chip,
          );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.onPrimaryContainer),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// 3) ActiveContractRibbon
/// ----------------------------
class ActiveContractRibbon extends StatelessWidget {
  final ContractRibbonData data;

  final VoidCallback? onTap; // optional: open contract detail modal
  final VoidCallback? onClaim;

  const ActiveContractRibbon({
    super.key,
    required this.data,
    this.onTap,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = data.isCompleted ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = data.isCompleted ? cs.onPrimaryContainer : cs.onSurface;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in_rounded, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _ThinProgressBar(
                        value01: data.progress01.clamp(0.0, 1.0),
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      data.progressText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: fg.withOpacity(0.85),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (data.isCompleted) ...[
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onClaim,
              child: const Text('Claim'),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: (onTap == null)
          ? card
          : InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: card,
            ),
    );
  }
}

class _ThinProgressBar extends StatelessWidget {
  final double value01;
  final double height;

  const _ThinProgressBar({
    required this.value01,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value01,
          backgroundColor: cs.surfaceContainerLow,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          minHeight: height,
        ),
      ),
    );
  }
}

/// ----------------------------
/// 4) TierSection
/// ----------------------------
/// Sliver-friendly pattern:
/// - TierSectionHeader (box)
/// - SliverList for IndustryTiles (outside this widget)
///
/// This widget returns a regular Column (no internal scroll).
/// For slivers, wrap TierSection inside SliverToBoxAdapter.
/// Or use TierSectionSliver which outputs slivers directly.
class TierSection extends StatelessWidget {
  final String tierName;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  final List<Widget> industryTiles; // provide IndustryTile widgets, already keyed

  const TierSection({
    super.key,
    required this.tierName,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.industryTiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TierSectionHeader(
            tierName: tierName,
            isExpanded: isExpanded,
            onToggleExpanded: onToggleExpanded,
          ),
          if (isExpanded) ...[
            const SizedBox(height: 10),
            ...industryTiles,
          ],
        ],
      ),
    );
  }
}

/// Sliver-native TierSection output (recommended for EmpireScreen).
class TierSectionSliver extends StatelessWidget {
  final String tierName;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const TierSectionSliver({
    super.key,
    required this.tierName,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TierSectionHeader(
              tierName: tierName,
              isExpanded: isExpanded,
              onToggleExpanded: onToggleExpanded,
            ),
          ),
        ),
        if (isExpanded)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                itemBuilder,
                childCount: itemCount,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                addSemanticIndexes: true,
              ),
            ),
          ),
      ],
    );
  }
}

class TierSectionHeader extends StatelessWidget {
  final String tierName;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const TierSectionHeader({
    super.key,
    required this.tierName,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onToggleExpanded,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tierName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// 5) IndustryTile
/// ----------------------------
class IndustryTile extends StatelessWidget {
  final IndustryTileData data;

  /// External state for expansion (keeps list rendering fast & deterministic).
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  /// UI actions
  final VoidCallback onUpgrade;
  final VoidCallback? onAssignManager;

  /// Optional: tap on tile (defaults to toggle)
  final VoidCallback? onTap;

  const IndustryTile({
    super.key,
    required this.data,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onUpgrade,
    this.onAssignManager,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final stateStyle = _IndustryStateStyle.from(context, data.state);
    final borderColor = stateStyle.borderColor ?? cs.outlineVariant.withOpacity(0.6);

    final tile = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsed header row (always visible)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IndustryIconBadge(
                    icon: data.icon,
                    state: data.state,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _IndustryMainInfo(
                      name: data.name,
                      outputName: data.outputResourceName,
                      outputIcon: data.outputIcon,
                      productionRateText: data.productionRateText,
                      level: data.level,
                      state: data.state,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _IndustryActionsColumn(
                    canUpgrade: data.canUpgrade,
                    upgradeCostText: data.upgradeCostText,
                    onUpgrade: onUpgrade,
                    hasManager: data.hasManager,
                    storageFill01: data.storageFill01,
                    storageText: data.storageText,
                  ),
                ],
              ),
            ),
          ),

          // Expanded area
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 140),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _IndustryExpandedPanel(
                data: data,
                onAssignManager: onAssignManager,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RepaintBoundary(
        child: KeyedSubtree(
          key: ValueKey(data.id),
          child: tile,
        ),
      ),
    );
  }
}

class _IndustryIconBadge extends StatelessWidget {
  final IconData icon;
  final IndustryVisualState state;

  const _IndustryIconBadge({
    required this.icon,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _IndustryStateStyle.from(context, state);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: style.badgeBg ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (style.borderColor ?? cs.outlineVariant).withOpacity(0.7)),
      ),
      child: Icon(icon, color: style.badgeFg ?? cs.onSurface, size: 22),
    );
  }
}

class _IndustryMainInfo extends StatelessWidget {
  final String name;
  final String outputName;
  final IconData outputIcon;
  final String productionRateText;
  final int level;
  final IndustryVisualState state;

  const _IndustryMainInfo({
    required this.name,
    required this.outputName,
    required this.outputIcon,
    required this.productionRateText,
    required this.level,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _IndustryStateStyle.from(context, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _StatePill(state: state),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(outputIcon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                outputName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              productionRateText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: style.rateColor ?? cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Lv $level',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _IndustryActionsColumn extends StatelessWidget {
  final bool canUpgrade;
  final String upgradeCostText;
  final VoidCallback onUpgrade;

  final bool hasManager;

  final double storageFill01;
  final String storageText;

  const _IndustryActionsColumn({
    required this.canUpgrade,
    required this.upgradeCostText,
    required this.onUpgrade,
    required this.hasManager,
    required this.storageFill01,
    required this.storageText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FilledButton.tonal(
          onPressed: canUpgrade ? onUpgrade : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            canUpgrade ? 'Upgrade ($upgradeCostText)' : 'Upgrade',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasManager ? Icons.badge_rounded : Icons.badge_outlined,
              size: 16,
              color: hasManager ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 64,
              child: _ThinProgressBar(
                value01: storageFill01.clamp(0.0, 1.0),
                height: 8,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              storageText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IndustryExpandedPanel extends StatelessWidget {
  final IndustryTileData data;
  final VoidCallback? onAssignManager;

  const _IndustryExpandedPanel({
    required this.data,
    this.onAssignManager,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inputs
          Text(
            'Inputs',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          if (data.inputs.isEmpty)
            Text(
              'None',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.inputs
                  .map(
                    (r) => _ResourceChip(
                      icon: r.icon,
                      name: r.name,
                      amount: r.amount,
                    ),
                  )
                  .toList(growable: false),
            ),

          const SizedBox(height: 12),

          // Multipliers
          Text(
            'Multipliers',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          if (data.multipliers.isEmpty)
            Text(
              'None',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.multipliers
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),

          const SizedBox(height: 12),

          // Upgrade details + manager
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upgrade Cost: ${data.upgradeCostText}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (data.canAssignManager) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onAssignManager,
                  icon: Icon(
                    data.hasManager ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                    size: 18,
                  ),
                  label: Text(data.hasManager ? 'Manager' : 'Assign'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final String amount;

  const _ResourceChip({
    required this.icon,
    required this.name,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$name $amount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Visual state pill: STARVED / CAPPED / BOOSTED (or hidden for normal).
class _StatePill extends StatelessWidget {
  final IndustryVisualState state;

  const _StatePill({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == IndustryVisualState.normal) return const SizedBox.shrink();

    final style = _IndustryStateStyle.from(context, state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.pillBorder),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.pillFg,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _IndustryStateStyle {
  final String label;

  final Color pillBg;
  final Color pillFg;
  final Color pillBorder;

  final Color? borderColor;
  final Color? badgeBg;
  final Color? badgeFg;
  final Color? rateColor;

  const _IndustryStateStyle({
    required this.label,
    required this.pillBg,
    required this.pillFg,
    required this.pillBorder,
    this.borderColor,
    this.badgeBg,
    this.badgeFg,
    this.rateColor,
  });

  static _IndustryStateStyle from(BuildContext context, IndustryVisualState state) {
    final cs = Theme.of(context).colorScheme;

    switch (state) {
      case IndustryVisualState.starved:
        return _IndustryStateStyle(
          label: 'STARVED',
          pillBg: cs.errorContainer.withOpacity(0.85),
          pillFg: cs.onErrorContainer,
          pillBorder: cs.error.withOpacity(0.4),
          borderColor: cs.error.withOpacity(0.55),
          badgeBg: cs.errorContainer.withOpacity(0.65),
          badgeFg: cs.onErrorContainer,
          rateColor: cs.onSurfaceVariant,
        );

      case IndustryVisualState.capped:
        return _IndustryStateStyle(
          label: 'CAPPED',
          pillBg: cs.surfaceContainerHighest,
          pillFg: cs.onSurfaceVariant,
          pillBorder: cs.outlineVariant.withOpacity(0.7),
          borderColor: cs.outline.withOpacity(0.5),
          badgeBg: cs.surfaceContainerHighest,
          badgeFg: cs.onSurface,
          rateColor: cs.onSurfaceVariant,
        );

      case IndustryVisualState.boosted:
        return _IndustryStateStyle(
          label: 'BOOSTED',
          pillBg: cs.primaryContainer.withOpacity(0.9),
          pillFg: cs.onPrimaryContainer,
          pillBorder: cs.primary.withOpacity(0.4),
          borderColor: cs.primary.withOpacity(0.55),
          badgeBg: cs.primaryContainer.withOpacity(0.7),
          badgeFg: cs.onPrimaryContainer,
          rateColor: cs.primary,
        );

      case IndustryVisualState.normal:
      default:
        return _IndustryStateStyle(
          label: '',
          pillBg: Colors.transparent,
          pillFg: cs.onSurface,
          pillBorder: Colors.transparent,
        );
    }
  }
}
