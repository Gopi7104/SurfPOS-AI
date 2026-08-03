import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_shadows.dart';
import '../pages/surf_ai_chat_page.dart';

/// Hero tag shared between this button and the small badge
/// [SurfAiChatPage] shows in its own header — see that page for the
/// matching `Hero`.
const surfAiHeroTag = 'surf-ai-fab';

/// The circular gradient + sparkle-icon visual itself, with no animation or
/// interaction — factored out so [SurfAiFloatingButton] and
/// [SurfAiChatPage]'s header badge render the exact same shape at two
/// different sizes, which is what makes the [Hero] flight between them read
/// as one continuous shape rather than two unrelated widgets cross-fading.
class SurfAiBadge extends StatelessWidget {
  const SurfAiBadge({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: AppShadows.primaryGlow,
      ),
      child:
          Icon(LucideIcons.sparkles, color: AppColors.white, size: size * 0.46),
    );
  }
}

/// The floating "Ask SurfAI" entry point — shown only on the Dashboard (see
/// `DashboardPage`, the only place this is used), positioned by the caller
/// (bottom-right, above the centered "New Sale" FAB). A soft Cream Soda
/// glow (the one brand color reserved for "AI Assistant" surfaces, see
/// `AppColors.secondary`'s own doc comment) breathes behind the badge and
/// pulses outward every few seconds; tapping gives a haptic tick, a
/// Material ripple, and a [Hero] flight into [SurfAiChatPage].
class SurfAiFloatingButton extends StatefulWidget {
  const SurfAiFloatingButton({this.onVerticalDrag, super.key});

  /// Fired with the drag's `delta.dy` when a vertical drag starts on this
  /// button — `null` (the default) leaves it exactly as before. Painted on
  /// top of Dashboard's scrollable content in a `Stack` (see `DashboardPage`),
  /// so a touch starting inside its bounds is claimed outright and the
  /// content underneath never gets a chance to scroll — same dead-zone
  /// problem `AppFab.onVerticalDrag` exists to work around, for the same
  /// reason. Wiring this callback lets the host forward the drag to its own
  /// scroll position instead.
  final ValueChanged<double>? onVerticalDrag;

  @override
  State<SurfAiFloatingButton> createState() => _SurfAiFloatingButtonState();
}

class _SurfAiFloatingButtonState extends State<SurfAiFloatingButton>
    with TickerProviderStateMixin {
  // Continuous, subtle "breathing" scale — reverse-repeat mirrors the
  // existing `ScanFrameAnimation` pattern elsewhere in this app.
  late final AnimationController _breathController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _breath = Tween(begin: 0.94, end: 1.0).animate(
    CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
  );

  // A soft ring that expands and fades once every few seconds, layered
  // behind the badge — the "small pulse" from the design brief, distinct
  // from the continuous breathing scale above. Deliberately a single
  // repeating `AnimationController` with an `Interval` (the pulse only
  // plays during the first fifth of each 5s cycle, then sits at rest for
  // the remaining four) rather than a `Timer.periodic` driving a one-shot
  // controller — a bare `Timer` left running for as long as this widget is
  // on screen trips `flutter_test`'s "pending timer" check in any test that
  // doesn't explicitly unmount the page before the test ends (which most
  // don't); an `AnimationController` doesn't have that problem.
  static const _pulseCycle = Duration(seconds: 5);
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: _pulseCycle,
  )..repeat();
  late final Animation<double> _pulseProgress = CurvedAnimation(
    parent: _pulseController,
    curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
  );
  late final Animation<double> _pulseScale =
      Tween(begin: 0.85, end: 1.6).animate(_pulseProgress);
  late final Animation<double> _pulseOpacity =
      Tween(begin: 0.35, end: 0.0).animate(_pulseProgress);

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _open(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SurfAiChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: widget.onVerticalDrag == null
          ? null
          : (details) => widget.onVerticalDrag!(details.delta.dy),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: _pulseOpacity.value,
                child: Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) =>
                  Transform.scale(scale: _breath.value, child: child),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _open(context),
                  child: const Hero(
                    tag: surfAiHeroTag,
                    child: SurfAiBadge(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
