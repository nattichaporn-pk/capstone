import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'bottom_nav.dart'; // หรือ bottom_nav_pkg.dart (BottomNavPkg) — API เหมือนกัน
import 'focus_timer_screen.dart';
import 'lock_app_screen.dart';
import 'pressable.dart';
import 'study_schedule_screen.dart';
import 'theme.dart';

/// หน้า Focus Hub ของแอป "Arntan" — ใช้ design system (theme.dart / pressable.dart / bottom_nav.dart)
class FocusHubScreen extends StatefulWidget {
  const FocusHubScreen({super.key});

  @override
  State<FocusHubScreen> createState() => _FocusHubScreenState();
}

class _FocusHubScreenState extends State<FocusHubScreen> {
  int _navIndex = 2; // แท็บ "Focus"

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    // เว้นล่างให้พ้น pill: safe area + ความสูง pill + margin + ช่องหายใจ
    final bottomInset = MediaQuery.paddingOf(context).bottom +
        kNavBarHeight +
        kNavBarMargin +
        kSpace4;

    return Scaffold(
      backgroundColor: kPageWarm,
      extendBody: true, // จำเป็นสำหรับ Liquid Glass nav
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // จอกว้าง → เนื้อหาเป็นคอลัมน์ 480 กึ่งกลาง
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      kGutter,
                      kSpace6,
                      kGutter,
                      bottomInset,
                    ),
                    children: [
                      const Text(
                        'สวัสดีตอนบ่าย',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: kInkSoft,
                        ),
                      ),
                      const SizedBox(height: kSpace1),
                      const Text(
                        'โฟกัสวันนี้',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: kSpace4),
                      _FocusCard(onStart: () => _push(const FocusTimerScreen())),
                      const SizedBox(height: kSpace6),
                      const _SectionTitle(title: 'ฟีเจอร์'),
                      const SizedBox(height: kSpace3),
                      _FeatureTile(
                        icon: CupertinoIcons.timer,
                        iconBg: kBrandFillSoft,
                        title: 'ตั้งเวลาโฟกัส',
                        subtitle: 'ใช้แบบ Pomodoro',
                        onTap: () => _push(const FocusTimerScreen()),
                      ),
                      const SizedBox(height: kSpace2),
                      _FeatureTile(
                        icon: CupertinoIcons.lock_shield,
                        iconBg: kPinkFill,
                        title: 'แอปที่บล็อก',
                        subtitle: 'บล็อกอยู่ 6 แอป',
                        onTap: () => _push(const LockAppScreen()),
                      ),
                      const SizedBox(height: kSpace2),
                      _FeatureTile(
                        icon: CupertinoIcons.person_2_fill,
                        iconBg: kYellowFill,
                        title: 'แบ่งปันเวลาอ่าน',
                        subtitle: 'อันดับเพื่อน · ชาเลนจ์ของกลุ่ม',
                        onTap: () => _push(const StudyScheduleScreen()),
                      ),
                      const SizedBox(height: kSpace6),
                      const _SectionTitle(title: 'ล่าสุด'),
                      const SizedBox(height: kSpace3),
                      const _RecentTile(
                        icon: CupertinoIcons.book_fill,
                        iconBg: kMintFill,
                        title: 'อ่านหนังสือเตรียมสอบ',
                        subtitle: 'วันนี้ 09:30',
                        trailing: '45 นาที',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace5),
      decoration: BoxDecoration(
        color: kSurface, // กรอบนอกสีขาว
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow, // การ์ดขาวบนพื้นขาว → ต้องมีเงา
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _StatColumn(label: 'โฟกัสวันนี้', value: '2 ชม. 15 น.'),
              ),
              Expanded(
                child: _StatColumn(label: 'เซสชันสำเร็จ', value: '5 งาน'),
              ),
            ],
          ),
          const SizedBox(height: kSpace5),
          PressableScale(
            onTap: onStart,
            child: Semantics(
              button: true,
              label: 'เริ่มโฟกัส',
              excludeSemantics: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: kSpace4),
                decoration: BoxDecoration(
                  color: kBrand,
                  borderRadius: BorderRadius.circular(kRadiusChip),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.play_arrow_solid,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: kSpace2),
                    Text(
                      'เริ่มโฟกัส',
                      style: TextStyle(
                        // ขาวบน kBrand = ข้อยกเว้นตั้งใจของผู้ใช้ (ดู theme.dart)
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kInk,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: kSpace1),
        Text(
          value,
          style: const TextStyle(
            color: kInk,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// แถวการ์ดขาว: ไอคอนพื้นพาสเทล + ชื่อ/คำอธิบาย (+ chevron ถ้ามี onTap)
class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow, // การ์ดขาวบนพื้นขาว → ต้องมีเงา
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(kRadiusChip),
            ),
            child: Icon(icon, color: kInk, size: 24), // ไอคอนเข้มบนพาสเทล
          ),
          const SizedBox(width: kSpace4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: kInkSoft),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '$title, $subtitle',
        excludeSemantics: true,
        child: _CardRow(
          icon: icon,
          iconBg: iconBg,
          title: title,
          subtitle: subtitle,
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: kInkFaint,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return _CardRow(
      icon: icon,
      iconBg: iconBg,
      title: title,
      subtitle: subtitle,
      trailing: Text(
        trailing,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kInkSoft,
        ),
      ),
    );
  }
} 