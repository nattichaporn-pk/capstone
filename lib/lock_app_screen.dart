import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoSwitch;
import 'package:flutter/material.dart';

import 'bottom_nav.dart'; // หรือ bottom_nav_pkg.dart (BottomNavPkg) — API เหมือนกัน
import 'pressable.dart';
import 'theme.dart';

class LockAppScreen extends StatefulWidget {
  const LockAppScreen({super.key});

  @override
  State<LockAppScreen> createState() => _LockAppScreenState();
}

class _LockAppScreenState extends State<LockAppScreen> {
  static const int _focusTabIndex = 2;

  // ข้อมูลจำลองสำหรับแอปในหน้าหลัก
  // 'color' = สีแบรนด์ของแต่ละแอป (ไอคอนใช้สีนี้ · พื้นเป็นสีเดียวกันแบบจาง)
  final List<Map<String, dynamic>> _myApps = [
    {'name': 'TikTok', 'icon': Icons.video_library, 'color': Colors.black, 'isLocked': true},
    {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': Colors.pink, 'isLocked': true},
    {'name': 'Facebook', 'icon': Icons.facebook, 'color': Colors.blue, 'isLocked': true},
    {'name': 'YouTube', 'icon': Icons.play_circle_filled, 'color': Colors.red, 'isLocked': true},
    {'name': 'X', 'icon': Icons.close, 'color': Colors.black87, 'isLocked': true},
    {'name': 'LINE', 'icon': Icons.chat, 'color': Colors.green, 'isLocked': true},
    {'name': 'Gmail', 'icon': Icons.email, 'color': Colors.redAccent, 'isLocked': false},
    {'name': 'Chrome', 'icon': Icons.language, 'color': Colors.orange, 'isLocked': false},
  ];

  // ข้อมูลจำลองสำหรับหน้าต่างเลือกแอปเพิ่มเติม
  final List<Map<String, dynamic>> _allApps = [
    {'name': 'WhatsApp', 'icon': Icons.wechat, 'color': Colors.green, 'isSelected': true},
    {'name': 'Messenger', 'icon': Icons.message, 'color': Colors.blueAccent, 'isSelected': true},
    {'name': 'Discord', 'icon': Icons.discord, 'color': Colors.indigo, 'isSelected': true},
    {'name': 'Twitch', 'icon': Icons.live_tv, 'color': Colors.purple, 'isSelected': false},
    {'name': 'Netflix', 'icon': Icons.movie, 'color': Colors.red, 'isSelected': false},
    {'name': 'Reddit', 'icon': Icons.reddit, 'color': Colors.deepOrange, 'isSelected': false},
    {'name': 'Pinterest', 'icon': Icons.push_pin, 'color': Colors.redAccent, 'isSelected': false},
    {'name': 'Spotify', 'icon': Icons.music_note, 'color': Colors.greenAccent, 'isSelected': false},
  ];

  int get _lockedCount => _myApps.where((app) => app['isLocked'] == true).length;

  void _showAddAppModal(BuildContext context) {
    // คำค้นหา: อยู่นอก builder เพื่อไม่ให้รีเซ็ตเมื่อชีตถูก rebuild
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final selectedCount =
                _allApps.where((a) => a['isSelected'] == true).length;

            // กรองตามชื่อแอป (ไม่สนตัวพิมพ์เล็ก/ใหญ่) — ว่าง = แสดงทั้งหมด
            final q = query.trim().toLowerCase();
            final visibleApps = q.isEmpty
                ? _allApps
                : _allApps
                    .where((a) => (a['name'] as String).toLowerCase().contains(q))
                    .toList();

            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Column(
                children: [
                  const SizedBox(height: kSpace2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpace2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PressableScale(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(kSpace3),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(color: kInkSoft, fontSize: 16),
                            ),
                          ),
                        ),
                        const Text(
                          'เลือกแอปที่จะบล็อก',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: kInk,
                          ),
                        ),
                        PressableScale(
                          onTap: () {
                            // กด "เสร็จสิ้น" → นำแอปที่ติ๊กไว้ไปเพิ่มบนสุดของหน้าหลัก และล็อกทันที
                            setState(() {
                              final selectedApps = _allApps
                                  .where((a) => a['isSelected'] == true)
                                  .toList();
                              for (final app in selectedApps) {
                                _myApps.insert(0, {
                                  'name': app['name'],
                                  'icon': app['icon'],
                                  'color': app['color'],
                                  'isLocked': true,
                                });
                                // เอาออกจากรายการค้นหา ไม่ให้ซ้ำซ้อน
                                _allApps.remove(app);
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(kSpace3),
                            child: Text(
                              'เสร็จสิ้น',
                              // kBrand = สีลิงก์/ปุ่มตาม design system
                              style: TextStyle(
                                color: kBrand,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(kSpace4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kFieldFill,
                        borderRadius: BorderRadius.circular(kRadiusChip),
                      ),
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setModalState(() => query = v),
                        style: const TextStyle(color: kInk, fontSize: 15),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            color: kInkSoft,
                            size: 18,
                          ),
                          hintText: 'ค้นหาแอป',
                          hintStyle: TextStyle(color: kDoneGrey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpace5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'เลือกแล้ว $selectedCount แอป',
                        style: const TextStyle(color: kInkSoft, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: kSpace2),
                  Expanded(
                    child: visibleApps.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่พบแอปที่ค้นหา',
                              style: TextStyle(color: kInkSoft, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        kGutter,
                        0,
                        kGutter,
                        MediaQuery.paddingOf(context).bottom + kSpace4,
                      ),
                      itemCount: visibleApps.length,
                      itemBuilder: (context, index) {
                        final app = visibleApps[index];
                        final selected = app['isSelected'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: kSpace2),
                          child: PressableScale(
                            onTap: () {
                              // ติ๊กถูก → ดันขึ้นบนสุด · เอาติ๊กออก → ลงล่างสุด
                              setModalState(() {
                                app['isSelected'] = !selected;
                                _allApps.remove(app);
                                if (app['isSelected'] == true) {
                                  _allApps.insert(0, app);
                                } else {
                                  _allApps.add(app);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kSpace4,
                                vertical: kSpace3,
                              ),
                              decoration: BoxDecoration(
                                color: kSurface, // การ์ดขาวลอยบนพื้นชีตเทา — ไม่ต้องใช้เงา
                                borderRadius: BorderRadius.circular(kRadiusCard),
                              ),
                              child: Row(
                                children: [
                                  _AppIcon(
                                    icon: app['icon'] as IconData,
                                    color: app['color'] as Color,
                                  ),
                                  const SizedBox(width: kSpace4),
                                  Expanded(
                                    child: Text(
                                      app['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: kInk,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : CupertinoIcons.circle,
                                    color: selected ? kBrand : kInkFaint,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageWarm,
      extendBody: true, // จำเป็นสำหรับ Liquid Glass Bottom Nav
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TitleRow(
                  title: 'แอปที่บล็อก',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      kGutter,
                      kSpace2,
                      kGutter,
                      MediaQuery.paddingOf(context).bottom + 100, // เผื่อแถบเมนู
                    ),
                    children: [
                      _buildStatusBox(),
                      const SizedBox(height: kSpace6),
                      const Text(
                        'รายการแอป',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kInkSoft,
                        ),
                      ),
                      const SizedBox(height: kSpace3),
                      ..._myApps.map(_buildAppListItem),
                      const SizedBox(height: kSpace1),
                      _buildAddAppButton(context),
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
        // (ถ้ามี shell/router กลางที่ควบคุมแท็บ ให้เปลี่ยนเป็น callback ของมัน)
        onTap: (_) => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }

  Widget _buildStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpace4),
      decoration: BoxDecoration(
        color: kPinkFill,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock_shield_fill, color: kPink, size: 22),
          const SizedBox(width: kSpace3),
          Expanded(
            child: Text(
              'กำลังบล็อก $_lockedCount แอป ระหว่างช่วงโฟกัส',
              style: const TextStyle(
                color: kInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppListItem(Map<String, dynamic> app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpace2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(kRadiusCard),
          boxShadow: kCardShadow, // การ์ดขาวบนพื้นขาว → ต้องมีเงา
        ),
        child: Row(
          children: [
            _AppIcon(icon: app['icon'] as IconData, color: app['color'] as Color),
            const SizedBox(width: kSpace4),
            Expanded(
              child: Text(
                app['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: kInk,
                ),
              ),
            ),
            CupertinoSwitch(
              value: app['isLocked'] == true,
              activeTrackColor: kBrand,
              onChanged: (bool value) {
                setState(() {
                  app['isLocked'] = value;
                  // เปิดล็อก → ขึ้นบนสุด · ปลดล็อก → ไปท้ายสุด
                  _myApps.remove(app);
                  if (value) {
                    _myApps.insert(0, app);
                  } else {
                    _myApps.add(app);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAppButton(BuildContext context) {
    return PressableScale(
      onTap: () => _showAddAppModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kBrandFillSoft,
          borderRadius: BorderRadius.circular(kRadiusChip),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: kInk, size: 18),
            SizedBox(width: kSpace2),
            Text(
              'เพิ่มแอปที่จะบล็อก',
              style: TextStyle(
                color: kInk,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable pieces
// ---------------------------------------------------------------------------

class _AppIcon extends StatelessWidget {
  final IconData icon;
  final Color color; // สีแบรนด์ของแอป
  const _AppIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // พื้นจางจากสีแอปเอง
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TitleRow({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpace2),
      child: Row(
        children: [
          PressableScale(
            onTap: onBack,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(CupertinoIcons.chevron_back, size: 22, color: kInk),
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