import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'bottom_nav.dart'; // หรือ bottom_nav_pkg.dart (BottomNavPkg) — API เหมือนกัน
import 'friend_data.dart';
import 'pressable.dart';
import 'theme.dart';

/// หน้าโปรไฟล์เพื่อน — เคารพการตั้งค่าความเป็นส่วนตัวของเพื่อน:
/// · เพื่อนปิด "สถานะออนไลน์" → ไม่เห็นว่ากำลังอ่านอยู่
/// · เพื่อนปิด "เวลาอ่าน" → ไม่เห็นสถิติเวลา และกราฟ 7 วัน (ยังส่งกำลังใจได้)
/// ข้อมูลทั้งหมดเป็นค่าจำลอง (ดู friend_data.dart)
class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key, required this.friend});

  final Friend friend;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  static const int _focusTabIndex = 2;
  static const _weekDays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  bool _cheered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
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
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TitleRow(
                  title: 'โปรไฟล์เพื่อน',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      kGutter,
                      kSpace2,
                      kGutter,
                      bottomInset,
                    ),
                    children: [
                      const SizedBox(height: kSpace2),
                      _ProfileHeader(friend: f),
                      const SizedBox(height: kSpace6),
                      if (f.showTime)
                        Row(
                          children: [
                            _StatBox(
                              value: '${f.totalHours} ช.ม.',
                              label: 'รวม',
                              bg: kBrandFillSoft,
                            ),
                            const SizedBox(width: kSpace3),
                            _StatBox(
                              value: formatMinutes(f.weekMinutes),
                              label: 'สัปดาห์นี้',
                              bg: kMintFill,
                            ),
                            const SizedBox(width: kSpace3),
                            _StatBox(
                              value: '${f.streak}',
                              label: 'วันติด',
                              icon: CupertinoIcons.flame_fill,
                              bg: kPeachFill,
                            ),
                          ],
                        )
                      else
                        _HiddenCard(name: f.name),
                      const SizedBox(height: kSpace6),
                      const _SectionLabel('ฉายา'),
                      const SizedBox(height: kSpace3),
                      Row(
                        children: [
                          const _BadgeBox(
                            icon: Icons.park,
                            iconColor: kSuccess,
                            bg: kMintFill,
                            label: 'นักปลูกต้นไม้',
                          ),
                          const SizedBox(width: kSpace3),
                          _BadgeBox(
                            icon: CupertinoIcons.flame_fill,
                            iconColor: kFlame,
                            bg: kPeachFill,
                            label: f.streak > 0
                                ? '${f.streak} วันติด'
                                : 'เริ่มสะสมวันติด',
                          ),
                          const SizedBox(width: kSpace3),
                          const _BadgeBox(
                            icon: CupertinoIcons.rosette,
                            iconColor: kGold,
                            bg: kYellowFill,
                            label: 'ยอดนักอ่าน',
                          ),
                        ],
                      ),
                      if (f.showTime) ...[
                        const SizedBox(height: kSpace6),
                        const _SectionLabel('7 วันล่าสุด'),
                        const SizedBox(height: kSpace3),
                        _WeekChart(heights: f.weekBars, days: _weekDays),
                      ],
                      const SizedBox(height: kSpace6),
                      _CheerButton(
                        name: f.name,
                        cheered: _cheered,
                        onTap: () => setState(() => _cheered = !_cheered),
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
        currentIndex: _focusTabIndex,
        // หน้านี้ push อยู่เหนือ shell → แตะแท็บใดก็กลับหน้าแรกของ stack
        onTap: (_) => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpace2),
      child: Row(
        children: [
          PressableScale(
            onTap: onBack,
            child: Semantics(
              button: true,
              label: 'ย้อนกลับ',
              excludeSemantics: true,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(CupertinoIcons.chevron_back, size: 22, color: kInk),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
          ),
          const SizedBox(width: 44), // ถ่วงให้ชื่อหน้าอยู่กึ่งกลางจริง
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: friend.avatarBg,
                  child: Text(
                    friend.initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                ),
              ),
              // จุดสถานะ: เขียว = กำลังอ่านอยู่ (เฉพาะเมื่อเพื่อนเปิดสถานะ)
              if (friend.visibleReading)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: kSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(color: kSurface, width: 3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: kSpace3),
        Text(
          friend.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        const SizedBox(height: kSpace2),
        _StatusPill(friend: friend),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color bg;
    final Widget lead;

    if (!friend.showStatus) {
      // เพื่อนปิดสถานะออนไลน์ → เรามองไม่เห็น
      text = 'ซ่อนสถานะออนไลน์';
      bg = kSurfaceAlt;
      lead = const Icon(CupertinoIcons.eye_slash, size: 14, color: kInkSoft);
    } else if (friend.isReadingNow) {
      text = 'กำลังอ่านอยู่ · ${friend.readingNowMinutes} นาทีแล้ว';
      bg = kMintFill;
      lead = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle),
      );
    } else {
      text = 'ไม่ได้อ่านอยู่ตอนนี้';
      bg = kSurfaceAlt;
      lead = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: kInkFaint, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace3, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          const SizedBox(width: kSpace2),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: friend.showStatus ? kInk : kInkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// เพื่อนปิดการแสดงเวลาอ่าน → แทนที่สถิติด้วยการ์ดนี้ (และซ่อนกราฟ 7 วัน)
class _HiddenCard extends StatelessWidget {
  const _HiddenCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpace5),
      decoration: BoxDecoration(
        color: kLavenderFill,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kSurface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.lock_fill, color: kInk, size: 22),
          ),
          const SizedBox(height: kSpace3),
          Text(
            '$nameปิดการแสดงเวลาอ่าน',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
          const SizedBox(height: kSpace1),
          const Text(
            'คุณจะเห็นเวลาอ่านและกราฟ 7 วันได้ เมื่อเพื่อนเปิดการแสดงอีกครั้ง\nแต่ยังส่งกำลังใจให้กันได้ตามปกติ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kInk),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.bg,
    this.icon,
  });

  final String value;
  final String label;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kSpace4, horizontal: kSpace1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(kRadiusCard),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: kFlame),
                  const SizedBox(width: kSpace1),
                ],
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpace1),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: kInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  const _BadgeBox({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpace1,
          vertical: kSpace3,
        ),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(kRadiusCard),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(kRadiusChip),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: kSpace2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kInkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.heights, required this.days});

  final List<double> heights;
  final List<String> days;

  static const double _maxBar = 100;

  @override
  Widget build(BuildContext context) {
    final todayIndex = heights.length - 1; // แท่งสุดท้าย = วันนี้ (ค่าจำลอง)

    return Container(
      padding: const EdgeInsets.all(kSpace5),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: (_maxBar * heights[i]).clamp(4.0, _maxBar),
                  decoration: BoxDecoration(
                    // วันนี้ = kBrand · วันอื่น = โทนอ่อนของสีเดียวกัน
                    color: i == todayIndex ? kBrand : kBrandFillSoft,
                    borderRadius: BorderRadius.circular(kSpace1),
                  ),
                ),
                const SizedBox(height: kSpace2),
                Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        i == todayIndex ? FontWeight.w700 : FontWeight.w500,
                    color: i == todayIndex ? kInk : kInkSoft,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  const _CheerButton({
    required this.name,
    required this.cheered,
    required this.onTap,
  });

  final String name;
  final bool cheered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = cheered ? 'ส่งกำลังใจให้$nameแล้ว' : 'ส่งกำลังใจให้$name';

    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: cheered,
        label: label,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: kDurQuick,
          curve: kCurveSmooth,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: kSpace4),
          decoration: BoxDecoration(
            // ยังไม่ส่ง = ชมพู (accent สนุก) + ข้อความเข้ม · ส่งแล้ว = ชมพูอ่อน
            color: cheered ? kPinkFill : kPink,
            borderRadius: BorderRadius.circular(kRadiusChip),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cheered ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: kInk,
                size: 18,
              ),
              const SizedBox(width: kSpace2),
              Text(
                label,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}