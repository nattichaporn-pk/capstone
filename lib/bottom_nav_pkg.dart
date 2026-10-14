import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'theme.dart';

// ── bottom nav ที่ใช้จริง: `GlassTabBar.bottom` (package `liquid_glass_widgets ^1.4.0`) ──────────
// Liquid Glass shader จริง — refraction + jelly physics + glow · สลับกลับแบบประกอบเองด้วย `kUseGlassPkgNav` (main.dart)
//
// ⚠️ ข้อแลก: +1 dep (Flutter ≥ 3.41) · ต้องมี `Material` ancestor → MyApp เพิ่ม `MaterialApp.builder` (Material transparency) ·
//   web/windows = shader "lightweight 2D" (premium = Impeller) · label ซ้ำ 2/แท็บ (เทสใช้ `.first`)
//
// Responsive: เนื้อหาทุกหน้าถูกจำกัดกว้าง `kMaxContentWidth` (480) กึ่งกลางบนจอกว้าง — pill ก็ต้องกว้างเท่ากัน
//   ไม่งั้นแถบยืดเต็มจอ แท็บกระจายห่างจากเนื้อหา · ทำโดยเพิ่ม `horizontalPadding` ตามความกว้างจอที่เกิน 480
//   (คง `GlassTabBar` เป็น bottomNavigationBar ตรง ๆ — Scaffold วัดความสูงเอง, ไม่ต้องห่อ → เลี่ยง P1.1)

/// pre-warm glass shaders — เรียกใน main() ก่อน runApp กัน flash เฟรมแรก
Future<void> initGlassNav() => LiquidGlassWidgets.initialize();

const _pkgTabs = <({IconData icon, IconData activeIcon, String label})>[
  (icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Home'),
  (
    icon: CupertinoIcons.checkmark_circle,
    activeIcon: CupertinoIcons.checkmark_circle_fill,
    label: 'To do list',
  ),
  (icon: CupertinoIcons.book, activeIcon: CupertinoIcons.book_fill, label: 'Focus'),
  (icon: CupertinoIcons.calendar, activeIcon: CupertinoIcons.calendar, label: 'Schedule'),
  (icon: CupertinoIcons.sparkles, activeIcon: CupertinoIcons.sparkles, label: 'AI Study'),
];

class BottomNavPkg extends StatelessWidget {
  const BottomNavPkg({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // จอกว้างเกิน kMaxContentWidth → ดัน pad ซ้าย-ขวาให้ pill กว้างสุด = kMaxContentWidth (ตรงกับคอลัมน์เนื้อหา)
    final sidePad = screenW > kMaxContentWidth
        ? (screenW - kMaxContentWidth) / 2 + kNavBarMargin
        : kNavBarMargin;

    return GlassTabBar.bottom(
      tabs: [
        for (final t in _pkgTabs)
          GlassTab(
            icon: Icon(t.icon),
            activeIcon: Icon(t.activeIcon),
            label: t.label,
            // ไม่ใส่ glowColor → capsule ขาวเรียบ ไม่มีเรืองสี (สไตล์ Apple Music)
          ),
      ],
      selectedIndex: currentIndex,
      onTabSelected: onTap,
      barHeight: kNavBarHeight,
      horizontalPadding: sidePad,
      iconSize: 24,
      labelFontSize: 11,
      // capsule = frosted ขาวเรียบ (แบบ Apple Music) ไม่มี glow สี
      indicatorColor: Colors.white,
      glowOpacity: 0, // ปิด glow รอบ capsule
      // capsule ขาวสะอาด → ไอคอน/ป้าย active ใช้ฟ้าอ่อน kNavActiveFg (#1565C0) บนขาว = 5.75:1
      // inactive = kNavInactiveFg เทา iOS (บน frost 5.34:1)
      selectedIconColor: kNavActiveFg,
      selectedLabelColor: kNavActiveFg,
      unselectedIconColor: kNavInactiveFg,
      unselectedLabelColor: kNavInactiveFg,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'LINE Seed Sans TH',
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'LINE Seed Sans TH',
        fontWeight: FontWeight.w500,
      ),
      // web/windows: shader เบา — เลี่ยง premium ที่เพี้ยนใน scroll view
      quality: GlassQuality.standard,
    );
  }
}
