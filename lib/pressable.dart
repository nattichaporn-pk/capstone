import 'package:flutter/widgets.dart';

import 'theme.dart';

// ห่อ widget ที่แตะได้ให้ "กดแล้วย่อ" แบบ iOS — ย่อ kPressScale + จางลงนิด แล้วสปริงกลับ (kCurveSnappy).
// ไม่มี ripple (iOS ไม่มี ripple). ใช้กับ ปุ่ม / การ์ด / chip / row ที่แตะได้.
// เคารพ reduced-motion: ถ้า disableAnimations → ไม่ย่อ (แต่ onTap ยังทำงาน).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = kPressScale,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pressed = _down && active && !reduceMotion;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onTapDown: active ? (_) => _set(true) : null,
      onTapUp: active ? (_) => _set(false) : null,
      onTapCancel: active ? () => _set(false) : null,
      child: AnimatedScale(
        scale: pressed ? widget.scale : 1.0,
        duration: kDurQuick,
        curve: kCurveSnappy,
        child: AnimatedOpacity(
          opacity: pressed ? 0.92 : 1.0,
          duration: kDurQuick,
          curve: kCurveSmooth,
          child: widget.child,
        ),
      ),
    );
  }
}
