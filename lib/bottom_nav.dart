import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;

import 'pressable.dart';
import 'theme.dart';

// แถบเมนูล่างของ AppShell — "Liquid Glass" pill ลอย (iOS 26 · Apple Music / App Store)
//
// แนวคิด Liquid Glass (Apple "Adopting Liquid Glass" + รีเสิร์ช material tiers):
//   วัสดุโปร่งแสง 3 ส่วน — (1) backdrop blur หนา (nav = 40–48 sigma)
//                          (2) "เพิ่มความอิ่มสี" ของเนื้อหาข้างหลัง (saturation boost)
//                          (3) overlay tint จาง + ไล่เงาหักเหแสงแนวทแยง + specular ที่ขอบ + เงา adaptive
//   (1)+(2) = `ImageFilter.compose(outer: ColorFilter.matrix(saturate), inner: blur)` — ไม่ใช้ fragment shader
//   (fragment shader `ImageFilter.shader` และ package `liquid_glass_*` = Impeller-only → พังบน web/windows
//    ที่เวิร์กโฟลว์ dev/สกรีนช็อตของโปรเจกต์นี้ใช้ · compose + gradient ทำงานทุก renderer)
//
// โครง layer (ลำดับสำคัญ): DecoratedBox(เงา pill) > ClipRRect > LayoutBuilder > Stack:
//   1) frost   = Positioned.fill(BackdropFilter(compose[saturate ∘ blur]) > ColoredBox(kGlassFill))  — เบลอ "พื้นหลัง"
//   2) sheen   = ไล่เงาโค้งกระจก (สว่างขอบบน → จางขอบล่าง)
//   3) edges   = ขอบนอก kGlassRim + ขอบใน 40% ขาว (glass edge)
//   4) capsule = _GlassCapsule — spring physics + "liquid morph" (ยืดตอนเดินทาง) · มี BackdropFilter ของตัวเอง
//   5) items   = Positioned.fill(Row crossAxisAlignment.stretch) ของ _NavItem
//   ⚠️ content ต้องเป็น "sibling" ของ frost ไม่ใช่ child — บนเว็บ BackdropFilter เบลอลูกตัวเองด้วย
//   ⚠️ capsule คำนวณ left/width เอง — ห้าม AnimatedAlign+FractionallySizedBox (เพี้ยนบนเว็บ)
//   ⚠️ ห่อด้วย Center(heightFactor: 1.0) เสมอ (P1.1) · AppShell ต้อง extendBody: true · ห้ามซ้อน glass เกิน 2 ชั้น (นี่ = 2)
//
// a11y (Apple ทำให้เอง — สะท้อนผ่าน MediaQuery):
//   • disableAnimations           → ไม่มี spring/ยืด (ตัด motion)
//   • highContrast / accessibleNavigation → พื้นทึบ ไม่มี blur/sheen/glow, ขอบเข้ม (= Reduce Transparency / Increase Contrast)
//
// WCAG: inactive #5B6472 บน frost (over white ≈ #F0F2F6) = 5.34:1 · active #1565C0 บน capsule ≈ 5.0–5.7:1 — ดู PAIRS
const kNavItems = <({IconData icon, IconData activeIcon, String label})>[
  (
    icon: CupertinoIcons.house,
    activeIcon: CupertinoIcons.house_fill,
    label: 'Home',
  ),
  (
    icon: CupertinoIcons.checkmark_circle,
    activeIcon: CupertinoIcons.checkmark_circle_fill,
    label: 'To do list',
  ),
  (
    icon: CupertinoIcons.book,
    activeIcon: CupertinoIcons.book_fill,
    label: 'Focus',
  ),
  (
    icon: CupertinoIcons.calendar,
    activeIcon: CupertinoIcons.calendar,
    label: 'Schedule',
  ),
  (
    icon: CupertinoIcons.sparkles,
    activeIcon: CupertinoIcons.sparkles,
    label: 'AI Study',
  ),
];

// เมทริกซ์เพิ่มความอิ่มสี (Rec. 709) — ใช้กับ backdrop ของ pill ให้สีข้างหลัง "สด" ขึ้นแบบกระจกจริง
List<double> _saturate(double s) {
  const lr = 0.213, lg = 0.715, lb = 0.072;
  return <double>[
    (1 - s) * lr + s, (1 - s) * lg, (1 - s) * lb, 0, 0, //
    (1 - s) * lr, (1 - s) * lg + s, (1 - s) * lb, 0, 0, //
    (1 - s) * lr, (1 - s) * lg, (1 - s) * lb + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = kNavItems.length;
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    // Apple: Reduce Transparency / Increase Contrast → กระจกกลายเป็นผิวทึบ
    final solid = media.highContrast || media.accessibleNavigation;
    final radius = BorderRadius.circular(kNavBarHeight / 2 + 6);

    return Center(
      // heightFactor: 1.0 = ห่อความสูงพอดีเนื้อหา ไม่งั้น Center พองเต็มจอ กิน body จนหน้าหาย (P1.1)
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kNavBarMargin,
              0,
              kNavBarMargin,
              kNavBarMargin,
            ),
            // เงาอยู่นอก ClipRRect (ไม่งั้นโดน clip)
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: const [
                  BoxShadow(
                    color: kGlassShadow,
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  height: kNavBarHeight,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final slotW = c.maxWidth / n;
                      return Stack(
                        children: [
                          // 1) frost — เบลอ "พื้นหลัง" + เพิ่มความอิ่มสี (Liquid Glass boost)
                          Positioned.fill(
                            child: solid
                                ? const ColoredBox(color: kGlassSolid)
                                : BackdropFilter(
                                    filter: ImageFilter.compose(
                                      outer: ColorFilter.matrix(
                                        _saturate(kGlassSaturation),
                                      ),
                                      inner: ImageFilter.blur(
                                        sigmaX: kGlassBlur,
                                        sigmaY: kGlassBlur,
                                      ),
                                    ),
                                    child: const ColoredBox(color: kGlassFill),
                                  ),
                          ),
                          // 2) sheen — ไล่เงาโค้งกระจก (สว่างขอบบน → จางขอบล่าง)
                          if (!solid)
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [kGlassSheenTop, kGlassSheenBottom],
                                  ),
                                ),
                              ),
                            ),
                          // 3) edges — ขอบนอกเข้มบาง + ขอบในสว่าง (glass edge)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                border: Border.all(color: kGlassRim, width: 1),
                              ),
                            ),
                          ),
                          if (!solid)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(1),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: radius,
                                    border: Border.all(
                                      color: kGlassSheen,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 4) liquid capsule — spring + ยืดตอนเดินทาง
                          _GlassCapsule(
                            index: currentIndex,
                            slotW: slotW,
                            trackWidth: c.maxWidth,
                            reduceMotion: reduceMotion,
                            solid: solid,
                          ),
                          // 5) ไอคอน + ป้าย — เต็มความสูง pill + จัดกึ่งกลางแนวตั้ง
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < kNavItems.length; i++)
                                  Expanded(
                                    child: _NavItem(
                                      item: kNavItems[i],
                                      active: i == currentIndex,
                                      onTap: () => onTap(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// capsule แท็บที่เลือก — "กระจกวางบนกระจก":
//   • spring physics (SpringSimulation) — เด้ง/หน่วงแบบ iOS · re-target กลางทางได้ (แตะรัว ๆ ไม่พัง)
//   • liquid morph: ระหว่างเลื่อน capsule "ยืด" ไปทางทิศที่ไป แล้วหดกลับตอนถึง (คำนวณจากระยะที่ยังเหลือ)
//   • มี BackdropFilter ของตัวเอง (child = gradient เท่านั้น ไม่ใช่ไอคอน → ปลอดภัยบนเว็บ) = "glass on glass"
//   • ไล่เงา ขาวสว่าง(บน)→ฟ้าขาวจาง(ล่าง) + ไล่เงาหักเหแสงแนวทแยง + specular ขอบบน + hairline รอบ
//   • เงานอก clip: เรืองฟ้าจาง (active cue) + ambient + contact
class _GlassCapsule extends StatefulWidget {
  const _GlassCapsule({
    required this.index,
    required this.slotW,
    required this.trackWidth,
    required this.reduceMotion,
    required this.solid,
  });

  final int index;
  final double slotW;
  final double trackWidth;
  final bool reduceMotion;
  final bool solid;

  @override
  State<_GlassCapsule> createState() => _GlassCapsuleState();
}

class _GlassCapsuleState extends State<_GlassCapsule>
    with SingleTickerProviderStateMixin {
  // unbounded → spring overshoot ได้ (ค่าเป็น "ดัชนีแท็บ" แบบ fractional)
  late final AnimationController _c = AnimationController.unbounded(vsync: this)
    ..value = widget.index.toDouble();

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 30, // ratio ≈ 0.84 — เด้งนิดเดียว แล้วนิ่ง
  );

  @override
  void didUpdateWidget(_GlassCapsule old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      final target = widget.index.toDouble();
      if (widget.reduceMotion) {
        _c.value = target;
      } else {
        _c.animateWith(
          SpringSimulation(_spring, _c.value, target, _c.velocity),
        );
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const capInset = 7.0;
    final capRadius = BorderRadius.circular(kNavBarHeight / 2 - 6);
    final target = widget.index.toDouble();

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pos = _c.value;
        // ระยะที่ยัง "ค้าง" ระหว่างเดินทาง → ยิ่งไกล ยิ่งยืด (สูงสุด ~1 ช่อง)
        final dist = (target - pos).abs().clamp(0.0, 1.0);
        final stretch = (widget.reduceMotion || widget.solid)
            ? 0.0
            : Curves.easeOut.transform(dist) * widget.slotW * 0.30;
        final movingRight = target >= pos;
        var left = movingRight
            ? pos * widget.slotW + capInset
            : pos * widget.slotW + capInset - stretch;
        var width = widget.slotW - capInset * 2 + stretch;
        // กัน spring overshoot ดัน capsule เลยขอบ pill (โดน ClipRRect กัด) — clamp แบบปลอดภัย (lower ≤ upper เสมอ)
        final maxLeft = (widget.trackWidth - 26.0).clamp(2.0, double.infinity);
        left = left.clamp(2.0, maxLeft);
        final maxWidth =
            (widget.trackWidth - left - 2.0).clamp(24.0, double.infinity);
        width = width.clamp(24.0, maxWidth);

        return Positioned(
          left: left,
          width: width,
          top: 8,
          bottom: 8,
          // เงา/เรืองแสงอยู่นอก ClipRRect ด้านใน (ไม่งั้นโดน clip)
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: capRadius,
              boxShadow: widget.solid
                  ? null
                  : const [
                      BoxShadow(color: kGlassCapGlow, blurRadius: 16),
                      BoxShadow(
                        color: Color(0x1F0B1220),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Color(0x140B1220),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: capRadius,
              child: Stack(
                children: [
                  // เนื้อกระจก: blur ของตัวเอง + ไล่เงาหักเหแสง (แนวตั้ง)
                  Positioned.fill(
                    child: widget.solid
                        ? const ColoredBox(color: Color(0xFFFFFFFF))
                        : BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [kGlassCapTop, kGlassCapBottom],
                                ),
                              ),
                            ),
                          ),
                  ),
                  // ไล่เงาหักเหแสงแนวทแยง (บน-ซ้ายสว่าง → จาง) — "refraction highlight"
                  if (!widget.solid)
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kGlassCapSheen, Color(0x00FFFFFF)],
                            stops: [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                  // specular ขอบบน (14% → จาง) + hairline รอบ
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: capRadius,
                        border: Border.all(
                          color: widget.solid
                              ? kNavActiveFg
                              : kGlassCapBorder,
                          width: widget.solid ? 1.5 : 1,
                        ),
                        gradient: widget.solid
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [kGlassCapRim, Color(0x00FFFFFF)],
                                stops: [0.0, 0.45],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final ({IconData icon, IconData activeIcon, String label}) item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // active: kNavActiveFg (ฟ้า) บน capsule กระจก ≥ 5.0:1 / inactive: kNavInactiveFg (เทา iOS) บน frost 5.34:1
    final color = active ? kNavActiveFg : kNavInactiveFg;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: PressableScale(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? item.activeIcon : item.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
