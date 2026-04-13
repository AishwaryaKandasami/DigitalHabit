import 'package:flutter/material.dart';

/// Constrains content to a max width for desktop/tablet, centering on large screens.
/// On mobile/small screens, content takes full width.
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Returns true if the screen is wide enough to be considered desktop/tablet
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  /// Returns true if running on a narrow mobile-like screen
  static bool isNarrow(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
}
