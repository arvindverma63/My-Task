import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared building blocks so every screen uses the same header, stat tile,
/// section label and empty state.

/// Flat page header: back button, title + subtitle, and trailing actions.
/// Handles the top safe-area inset and an optional loading bar.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool isLoading;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(canPop ? 8 : 16, 8, 14, 6),
            child: Row(
              children: [
                if (canPop) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    color: AppColors.title(isDark),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.2,
                          color: AppColors.title(isDark),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtitle(isDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ],
            ),
          ),
          SizedBox(
            height: 2,
            child: isLoading
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Compact header button. With a [label] it is the screen's primary action;
/// without one it is a quiet icon-only button.
class AppHeaderAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;

  const AppHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (label == null) {
      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.subtitle(isDark),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        style: IconButton.styleFrom(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.subtle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label!),
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Compact stat: tinted icon, value, and a short label.
class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppSpace.radius);

    return Material(
      color: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.15,
                          color: AppColors.title(isDark),
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label that introduces a group of content.
class AppSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const AppSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.subtitle(isDark),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
