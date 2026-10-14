import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'bottom_nav.dart'; // หรือ bottom_nav_pkg.dart (BottomNavPkg) — API เหมือนกัน
import 'friend_data.dart';
import 'friend_profile_screen.dart';
import 'pressable.dart';
import 'theme.dart';

/// หน้า "แบ่งปันเวลาอ่าน" — อันดับเวลาอ่านของเพื่อน + ชาเลนจ์ของกลุ่ม
/// · กดแถวเพื่อน → โปรไฟล์เพื่อน
/// · ตั้งค่าได้ว่าจะให้เพื่อนเห็น "เวลาอ่าน" / "สถานะออนไลน์" ของเรา (ไอคอนฟันเฟืองด้านขวาบน)
/// · ชาเลนจ์ของกลุ่ม: ตั้งเป้า (ชม.) + จำนวนวัน + เลือกเพื่อนที่ร่วมสะสมได้เอง (ไม่ฟิกสัปดาห์)
/// · เพื่อนที่ปิดการแสดงผล → เรามองไม่เห็นเวลา/สถานะของเขา และไม่นับในอันดับ
/// ข้อมูลทั้งหมดเป็นค่าจำลอง (ดู friend_data.dart)
class StudyScheduleScreen extends StatefulWidget {
  const StudyScheduleScreen({super.key});

  @override
  State<StudyScheduleScreen> createState() => _StudyScheduleScreenState();
}

class _StudyScheduleScreenState extends State<StudyScheduleScreen> {
  static const int _focusTabIndex = 2;

  int _tab = 0; // 0 = วันนี้, 1 = สัปดาห์นี้
  final Set<String> _cheered = {};

  // ชาเลนจ์ของกลุ่ม — ตั้งเป้า (ชม.) + จำนวนวัน + คนที่ร่วมสะสมได้เอง
  double _goalHours = 20;
  bool _customGoal = false; // false = ระบบแนะนำ · true = กลุ่มตั้งเอง
  int _durationDays = 7;
  int _daysElapsed = 2; // ค่าจำลอง: ผ่านมาแล้วกี่วัน

  // เพื่อนทั้งหมด (เพิ่มได้จากปุ่มเพิ่มเพื่อน — ตอนนี้เก็บคำขอที่ส่งไว้เฉยๆ)
  final List<Friend> _friends = List.of(kMockFriends);
  final Set<String> _pendingRequests = {};

  // รหัสเพื่อนที่ร่วมชาเลนจ์ (ไม่รวมตัวเรา — ตัวเราร่วมเสมอ) · ค่าเริ่มต้น = 3 คนแรก
  late final Set<String> _participants = {
    for (final f in _friends.take(3)) f.code,
  };

  int get _myMinutes => _tab == 0 ? 45 : 310;

  /// เพื่อนที่เปิดเวลา เรียงมาก → น้อย แล้วต่อด้วยเพื่อนที่ปิดเวลา (ไม่นับอันดับ)
  List<Friend> get _sorted {
    final visible = _friends.where((f) => f.showTime).toList()
      ..sort((a, b) => b.minutesFor(_tab).compareTo(a.minutesFor(_tab)));
    final hidden = _friends.where((f) => !f.showTime).toList();
    return [...visible, ...hidden];
  }

  int get _visibleCount => _friends.where((f) => f.showTime).length;
  int get _myRank =>
      _friends
          .where((f) => f.showTime && f.minutesFor(_tab) > _myMinutes)
          .length +
      1;

  int get _daysLeft {
    final left = _durationDays - _daysElapsed;
    return left < 0 ? 0 : left;
  }

  double get _doneHours =>
      (kMyChallengeMinutes +
          _friends
              .where((f) => _participants.contains(f.code))
              .fold<int>(0, (s, f) => s + f.challengeMinutes)) /
      60;

  void _toggleCheer(String code) => setState(() {
        if (!_cheered.remove(code)) _cheered.add(code);
      });

  void _openProfile(Friend f) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: f)),
    );
  }

  void _openPrivacy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ปล่อยให้ชีตสูงตามเนื้อหา (ไม่โดนจำกัดที่ 9/16 ของจอ)
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      builder: (_) => const _PrivacySheet(),
    );
  }

  void _openChallenge() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      builder: (_) => _ChallengeSheet(
        friends: _friends,
        goalHours: _goalHours,
        customGoal: _customGoal,
        durationDays: _durationDays,
        daysLeft: _daysLeft,
        participants: Set.of(_participants),
        onApply: (goal, custom, days, people) => setState(() {
          // เปลี่ยนจำนวนวัน = เริ่มนับวันใหม่
          if (days != _durationDays) _daysElapsed = 0;
          _goalHours = goal;
          _customGoal = custom;
          _durationDays = days;
          _participants
            ..clear()
            ..addAll(people);
        }),
      ),
    );
  }

  void _openAddFriend() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      builder: (_) => _AddFriendSheet(
        existingCodes: _friends.map((f) => f.code).toSet(),
        pendingCodes: _pendingRequests,
        onSend: (code) => setState(() => _pendingRequests.add(code)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // เว้นล่างให้พ้น pill: safe area + ความสูง pill + margin + ช่องหายใจ
    final bottomInset = MediaQuery.paddingOf(context).bottom +
        kNavBarHeight +
        kNavBarMargin +
        kSpace4;
    final sorted = _sorted;
    final liveFriends = _friends.where((f) => f.visibleReading).toList();

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
                _TitleBar(
                  onBack: () => Navigator.maybePop(context),
                  onPrivacy: _openPrivacy,
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
                      if (liveFriends.isNotEmpty) ...[
                        _LiveBanner(
                          friend: liveFriends.first,
                          onTap: () => _openProfile(liveFriends.first),
                        ),
                        const SizedBox(height: kSpace3),
                      ],
                      _ChallengeCard(
                        daysLeft: _daysLeft,
                        durationDays: _durationDays,
                        doneHours: _doneHours,
                        goalHours: _goalHours,
                        peopleCount: _participants.length + 1,
                        onTap: _openChallenge,
                      ),
                      const SizedBox(height: kSpace4),
                      _Segmented(
                        labels: const ['วันนี้', 'สัปดาห์นี้'],
                        selected: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: kSpace3),
                      ListenableBuilder(
                        listenable:
                            Listenable.merge([myShowTime, myShowStatus]),
                        builder: (_, __) => _MeCard(
                          rank: _myRank,
                          total: _visibleCount + 1,
                          minutes: _myMinutes,
                          timeVisible: myShowTime.value,
                          statusVisible: myShowStatus.value,
                          onPrivacy: _openPrivacy,
                        ),
                      ),
                      const SizedBox(height: kSpace5),
                      const Text(
                        'อันดับเพื่อน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: kSpace1),
                      const Text(
                        'เพื่อนที่ปิดการแสดงเวลาอ่านจะไม่นับในอันดับ',
                        style: TextStyle(fontSize: 13, color: kInkSoft),
                      ),
                      const SizedBox(height: kSpace3),
                      _Leaderboard(
                        friends: sorted,
                        tab: _tab,
                        cheered: _cheered,
                        onCheer: _toggleCheer,
                        onOpen: _openProfile,
                      ),
                      const SizedBox(height: kSpace3),
                      _AddFriendButton(onTap: _openAddFriend),
                      if (_pendingRequests.isNotEmpty) ...[
                        const SizedBox(height: kSpace3),
                        Text(
                          'ส่งคำขอแล้ว ${_pendingRequests.length} คน · รอเพื่อนยืนยัน',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kInkSoft,
                          ),
                        ),
                      ],
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
// Title bar (+ ปุ่มความเป็นส่วนตัว)
// ---------------------------------------------------------------------------

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.onBack, required this.onPrivacy});

  final VoidCallback onBack;
  final VoidCallback onPrivacy;

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
          const Expanded(
            child: Text(
              'แบ่งปันเวลาอ่าน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
          ),
          PressableScale(
            onTap: onPrivacy,
            child: Semantics(
              button: true,
              label: 'ตั้งค่าการมองเห็นของฉัน',
              excludeSemantics: true,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(CupertinoIcons.gear, size: 22, color: kInk),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner / challenge / segmented / me
// ---------------------------------------------------------------------------

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpace3,
          vertical: kSpace3,
        ),
        decoration: BoxDecoration(
          color: kMintFill,
          borderRadius: BorderRadius.circular(kRadiusChip),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: kSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: kSpace2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: friend.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' กำลังอ่านอยู่ตอนนี้ · ${friend.readingNowMinutes} นาทีแล้ว',
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: kInk),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: kInk),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.daysLeft,
    required this.durationDays,
    required this.doneHours,
    required this.goalHours,
    required this.peopleCount,
    required this.onTap,
  });

  final int daysLeft;
  final int durationDays;
  final double doneHours;
  final double goalHours;
  final int peopleCount; // รวมตัวเรา
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (doneHours / goalHours).clamp(0.0, 1.0);

    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'ชาเลนจ์ของกลุ่ม ดูรายละเอียดและตั้งค่า',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(kSpace4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kYellowFill, kPeachFill],
            ),
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kSunDeep,
                      borderRadius: BorderRadius.circular(kRadiusChip),
                    ),
                    child: const Icon(
                      CupertinoIcons.rosette,
                      color: kInkOnYellow,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: kSpace3),
                  const Expanded(
                    child: Text(
                      'ชาเลนจ์ของกลุ่ม',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                  ),
                  Text(
                    'เหลือ $daysLeft วัน',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(width: kSpace1),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: kInk),
                ],
              ),
              const SizedBox(height: kSpace3),
              Text(
                '$peopleCount คนอ่านรวม ${goalHours.toStringAsFixed(0)} ชม. '
                'ภายใน $durationDays วัน · รับตรา "นักอ่านทีม"',
                style: const TextStyle(fontSize: 13, color: kInk),
              ),
              const SizedBox(height: kSpace3),
              ClipRRect(
                borderRadius: BorderRadius.circular(kSpace1),
                child: Stack(
                  children: [
                    Container(height: kSpace3, color: kSurface),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(height: kSpace3, color: kPink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpace1),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${doneHours.toStringAsFixed(1)} / ${goalHours.toStringAsFixed(0)} ชม.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace1),
      decoration: BoxDecoration(
        color: kSurfaceAlt,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: PressableScale(
                onTap: () => onChanged(i),
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  label: labels[i],
                  excludeSemantics: true,
                  child: AnimatedContainer(
                    duration: kDurQuick,
                    curve: kCurveSmooth,
                    padding: const EdgeInsets.symmetric(vertical: kSpace3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? kBrandFill : Colors.transparent,
                      borderRadius: BorderRadius.circular(kRadiusChip),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            i == selected ? FontWeight.w700 : FontWeight.w500,
                        color: i == selected ? kInk : kInkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeCard extends StatelessWidget {
  const _MeCard({
    required this.rank,
    required this.total,
    required this.minutes,
    required this.timeVisible,
    required this.statusVisible,
    required this.onPrivacy,
  });

  final int rank;
  final int total;
  final int minutes;
  final bool timeVisible;
  final bool statusVisible;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final bothVisible = timeVisible && statusVisible;
    final label = bothVisible
        ? 'เพื่อนเห็นเวลาและสถานะของคุณ'
        : (!timeVisible && !statusVisible)
            ? 'ซ่อนเวลาและสถานะจากเพื่อน'
            : timeVisible
                ? 'ซ่อนสถานะออนไลน์จากเพื่อน'
                : 'ซ่อนเวลาอ่านจากเพื่อน';

    return Container(
      padding: const EdgeInsets.all(kSpace4),
      decoration: BoxDecoration(
        color: kBrandFillSoft,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: kSurface,
                child: Icon(CupertinoIcons.person_fill, color: kBrand, size: 22),
              ),
              const SizedBox(width: kSpace3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คุณ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'อันดับ $rank จาก $total คน',
                      style: const TextStyle(fontSize: 13, color: kInk),
                    ),
                  ],
                ),
              ),
              Text(
                '$minutes นาที',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpace3),
          PressableScale(
            onTap: onPrivacy,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: kSpace3,
                vertical: kSpace2,
              ),
              decoration: BoxDecoration(
                color: kSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(kRadiusChip),
              ),
              child: Row(
                children: [
                  Icon(
                    bothVisible
                        ? CupertinoIcons.person_2_fill
                        : CupertinoIcons.lock_fill,
                    size: 16,
                    color: kInk,
                  ),
                  const SizedBox(width: kSpace2),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                  ),
                  const Text(
                    'ตั้งค่า',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(width: kSpace1),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: kInk),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({
    required this.friends,
    required this.tab,
    required this.cheered,
    required this.onCheer,
    required this.onOpen,
  });

  final List<Friend> friends; // เรียงแล้ว: เปิดเวลาก่อน → ปิดเวลาท้ายสุด
  final int tab;
  final Set<String> cheered;
  final ValueChanged<String> onCheer;
  final ValueChanged<Friend> onOpen;

  @override
  Widget build(BuildContext context) {
    // อันดับนับเฉพาะเพื่อนที่เปิดเวลา (ปิดเวลา = null) — คำนวณก่อน build เพื่อไม่ให้มี side effect ใน builder
    final ranks = <int?>[];
    var next = 0;
    for (final f in friends) {
      ranks.add(f.showTime ? ++next : null);
    }

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow, // การ์ดขาวบนพื้นขาว → ต้องมีเงา
      ),
      child: Column(
        children: [
          for (var i = 0; i < friends.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: kHairline,
                indent: kSpace4,
                endIndent: kSpace4,
              ),
            _FriendRow(
              rank: ranks[i],
              friend: friends[i],
              tab: tab,
              cheered: cheered.contains(friends[i].code),
              onCheer: () => onCheer(friends[i].code),
              onOpen: () => onOpen(friends[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int? rank; // null = ซ่อนเวลา (ไม่นับอันดับ)

  @override
  Widget build(BuildContext context) {
    if (rank == null) {
      return const SizedBox(
        width: 28,
        child: Icon(CupertinoIcons.lock_fill, size: 15, color: kInkFaint),
      );
    }
    // 1–3 = เหรียญทอง/เงิน/ทองแดงอ่อน · อื่นๆ = ตัวเลขเฉยๆ
    final medal = switch (rank!) {
      1 => kSunDeep,
      2 => const Color(0xFFDDE1E8),
      3 => kPeachFill,
      _ => null,
    };
    return SizedBox(
      width: 28,
      height: 28,
      child: Container(
        alignment: Alignment.center,
        decoration: medal == null
            ? null
            : BoxDecoration(color: medal, shape: BoxShape.circle),
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 14,
            fontWeight: medal != null ? FontWeight.w800 : FontWeight.w600,
            color: medal != null ? kInk : kInkSoft,
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.rank,
    required this.friend,
    required this.tab,
    required this.cheered,
    required this.onCheer,
    required this.onOpen,
  });

  final int? rank;
  final Friend friend;
  final int tab;
  final bool cheered;
  final VoidCallback onCheer;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ส่วนที่กดแล้วไปโปรไฟล์ = ทั้งแถวยกเว้นปุ่มกำลังใจ
        Expanded(
          child: PressableScale(
            onTap: onOpen,
            child: Semantics(
              button: true,
              label: 'ดูโปรไฟล์${friend.name}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: kSpace4,
                  top: kSpace2,
                  bottom: kSpace2,
                ),
                child: Row(
                  children: [
                    _RankBadge(rank: rank),
                    const SizedBox(width: kSpace3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: friend.avatarBg,
                              child: Text(
                                friend.initial,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                            ),
                          ),
                          if (friend.visibleReading)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: kSuccess,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kSurface, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: kSpace3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                          if (friend.streak > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.flame_fill,
                                  color: kFlame,
                                  size: 14,
                                ),
                                const SizedBox(width: kSpace1),
                                Text(
                                  '${friend.streak} วันติด',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kInkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (friend.visibleReading) ...[
                            const SizedBox(height: 2),
                            const Text(
                              'กำลังอ่านอยู่',
                              style: TextStyle(fontSize: 13, color: kInkSoft),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: kSpace2),
                    if (friend.showTime)
                      Text(
                        '${friend.minutesFor(tab)} นาที',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      )
                    else
                      const Text(
                        'ซ่อนเวลา',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kInkSoft,
                        ),
                      ),
                    const SizedBox(width: kSpace1),
                  ],
                ),
              ),
            ),
          ),
        ),
        PressableScale(
          onTap: onCheer,
          child: Semantics(
            button: true,
            selected: cheered,
            label: 'ส่งกำลังใจให้${friend.name}',
            excludeSemantics: true,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: AnimatedContainer(
                  duration: kDurQuick,
                  curve: kCurveSmooth,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cheered ? kPinkFill : kSurfaceAlt,
                    borderRadius: BorderRadius.circular(kRadiusChip),
                  ),
                  child: Icon(
                    cheered
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: cheered ? kPink : kInkSoft,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ปุ่มเพิ่มเพื่อน (เส้นประ)
// ---------------------------------------------------------------------------

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'เพิ่มเพื่อน',
        excludeSemantics: true,
        child: CustomPaint(
          foregroundPainter: const _DashedRRectPainter(
            color: kBrand,
            radius: kRadiusCard,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: kSpace4),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.person_add_solid, color: kBrand, size: 18),
                SizedBox(width: kSpace2),
                Text(
                  'เพิ่มเพื่อน',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _stroke = 1.5;
  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

// ---------------------------------------------------------------------------
// Sheet: การมองเห็นของฉัน
// ---------------------------------------------------------------------------

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // จอเตี้ย/ฟอนต์ใหญ่ → เลื่อนได้ ไม่ overflow
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(kGutter, kSpace5, kGutter, kSpace4),
        child: ListenableBuilder(
          listenable: Listenable.merge([myShowTime, myShowStatus]),
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'การมองเห็นของฉัน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: kSpace1),
              const Text(
                'เลือกได้ว่าจะให้เพื่อนเห็นอะไรของคุณ — เพื่อนก็เลือกของเขาเองเหมือนกัน',
                style: TextStyle(fontSize: 13, color: kInkSoft),
              ),
              const SizedBox(height: kSpace4),
              _PrivacyTile(
                icon: CupertinoIcons.clock_fill,
                iconBg: kBrandFillSoft,
                title: 'แสดงเวลาอ่านของฉัน',
                subtitle: myShowTime.value
                    ? 'เพื่อนเห็นเวลา กราฟ และอันดับของคุณ'
                    : 'ซ่อนอยู่ · คุณไม่นับในอันดับของเพื่อน',
                value: myShowTime.value,
                onChanged: (v) => myShowTime.value = v,
              ),
              const SizedBox(height: kSpace2),
              _PrivacyTile(
                icon: CupertinoIcons.dot_radiowaves_left_right,
                iconBg: kMintFill,
                title: 'แสดงสถานะออนไลน์',
                subtitle: myShowStatus.value
                    ? 'เพื่อนเห็นว่าคุณ "กำลังอ่านอยู่"'
                    : 'ซ่อนอยู่ · เพื่อนไม่เห็นว่าคุณกำลังอ่าน',
                value: myShowStatus.value,
                onChanged: (v) => myShowStatus.value = v,
              ),
              const SizedBox(height: kSpace4),
              Container(
                padding: const EdgeInsets.all(kSpace3),
                decoration: BoxDecoration(
                  color: kYellowFill,
                  borderRadius: BorderRadius.circular(kRadiusChip),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, size: 18, color: kInk),
                    SizedBox(width: kSpace2),
                    Expanded(
                      child: Text(
                        'ถ้าเพื่อนปิดการแสดงเวลาหรือสถานะ คุณจะมองไม่เห็นข้อมูลนั้นของเขาเช่นกัน '
                        'แต่ยังส่งกำลังใจให้กันได้ · เวลาที่ซ่อนยังนับรวมในเป้าหมายทีมของชาเลนจ์',
                        style: TextStyle(fontSize: 13, color: kInk),
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

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
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
            child: Icon(icon, color: kInk, size: 22),
          ),
          const SizedBox(width: kSpace3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: kInkSoft),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: kBrand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet: ชาเลนจ์ของกลุ่ม — ตั้งเป้า (ชม.) · จำนวนวัน · เลือกคนที่ร่วมสะสม
// ---------------------------------------------------------------------------

/// เป้าที่ระบบแนะนำ ≈ [_kSuggestHoursPerPersonDay] ชม./คน/วัน ปัดเป็นหลัก [_kGoalRound] ชม.
/// (ค่าจำลอง — ของจริงให้คำนวณจากประวัติการอ่านของกลุ่มที่ backend)
const double _kSuggestHoursPerPersonDay = 0.75;
const int _kGoalRound = 5;

double _suggestGoal({required int people, required int days}) {
  final rounded =
      (people * days * _kSuggestHoursPerPersonDay / _kGoalRound).round() *
          _kGoalRound;
  return (rounded < _kGoalRound ? _kGoalRound : rounded).toDouble();
}

class _Member {
  const _Member({
    required this.code,
    required this.name,
    required this.minutes,
    required this.hidden,
    required this.bg,
  });

  final String? code; // null = ตัวเรา (ร่วมเสมอ)
  final String name;
  final int minutes;
  final bool hidden; // ซ่อนเวลา → นับรวมในทีม แต่ไม่โชว์รายคน
  final Color bg;

  bool get isMe => code == null;
}

class _ChallengeSheet extends StatefulWidget {
  const _ChallengeSheet({
    required this.friends,
    required this.goalHours,
    required this.customGoal,
    required this.durationDays,
    required this.daysLeft,
    required this.participants,
    required this.onApply,
  });

  final List<Friend> friends;
  final double goalHours;
  final bool customGoal;
  final int durationDays;
  final int daysLeft;
  final Set<String> participants; // รหัสเพื่อนที่ร่วมชาเลนจ์ (ไม่รวมตัวเรา)
  final void Function(
    double goalHours,
    bool custom,
    int days,
    Set<String> participants,
  ) onApply;

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  static const double _minGoal = 1;
  static const double _maxGoal = 200;
  static const int _minDays = 1;
  static const int _maxDays = 60;
  static const _goalPresets = [10, 20, 30, 50];
  static const _dayPresets = [3, 7, 14, 30];

  late bool _custom = widget.customGoal;
  late double _goal = widget.goalHours;
  late int _days = widget.durationDays;
  late final Set<String> _people = Set.of(widget.participants);

  int get _peopleCount => _people.length + 1; // +1 = ตัวเรา
  double get _systemGoal => _suggestGoal(people: _peopleCount, days: _days);
  double get _effectiveGoal => _custom ? _goal : _systemGoal;

  /// ไม่เปลี่ยนจำนวนวัน = นับต่อจากเดิม · เปลี่ยนแล้วบันทึก = เริ่มนับวันใหม่
  int get _daysLeft => _days == widget.durationDays ? widget.daysLeft : _days;

  void _togglePerson(String code) => setState(() {
        if (!_people.remove(code)) _people.add(code);
      });

  @override
  Widget build(BuildContext context) {
    final members = <_Member>[
      _Member(
        code: null,
        name: 'คุณ',
        minutes: kMyChallengeMinutes,
        hidden: !myShowTime.value,
        bg: kBrandFillSoft,
      ),
      for (final f in widget.friends)
        _Member(
          code: f.code,
          name: f.name,
          minutes: f.challengeMinutes,
          hidden: !f.showTime,
          bg: f.avatarBg,
        ),
    ];
    final joined =
        members.where((m) => m.isMe || _people.contains(m.code)).toList();
    final doneMinutes = joined.fold<int>(0, (s, m) => s + m.minutes);
    final maxMinutes =
        joined.fold<int>(1, (s, m) => m.minutes > s ? m.minutes : s);
    final done = doneMinutes / 60;
    final goal = _effectiveGoal;
    final progress = (done / goal).clamp(0.0, 1.0);

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kGutter, kSpace5, kGutter, kSpace4),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kSunDeep,
                          borderRadius: BorderRadius.circular(kRadiusChip),
                        ),
                        child: const Icon(
                          CupertinoIcons.rosette,
                          color: kInkOnYellow,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: kSpace3),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ชาเลนจ์ของกลุ่ม',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: kInk,
                              ),
                            ),
                            Text(
                              'อ่านรวมกันให้ถึงเป้า ภายในจำนวนวันที่ตั้ง',
                              style: TextStyle(fontSize: 13, color: kInkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpace4),

                  // ความคืบหน้า
                  Container(
                    padding: const EdgeInsets.all(kSpace4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kYellowFill, kPeachFill],
                      ),
                      borderRadius: BorderRadius.circular(kRadiusCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              done.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6, left: kSpace1),
                              child: Text(
                                '/ ${goal.toStringAsFixed(0)} ชม.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kInk,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'เหลือ $_daysLeft วัน',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpace2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(kSpace1),
                          child: Stack(
                            children: [
                              Container(height: kSpace3, color: kSurface),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(height: kSpace3, color: kPink),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kSpace3),
                        const Row(
                          children: [
                            Icon(CupertinoIcons.gift_fill, size: 16, color: kInk),
                            SizedBox(width: kSpace2),
                            Expanded(
                              child: Text(
                                'รางวัล: ตรา "นักอ่านทีม" ให้ทุกคนที่ร่วม เมื่อถึงเป้า',
                                style: TextStyle(fontSize: 13, color: kInk),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSpace5),

                  // เป้าหมาย (ชม.)
                  const _SheetHeading('เป้าหมายรวมของกลุ่ม'),
                  const SizedBox(height: kSpace3),
                  Container(
                    padding: const EdgeInsets.all(kSpace1),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                    ),
                    child: Row(
                      children: [
                        _GoalModeButton(
                          label: 'ระบบแนะนำ',
                          selected: !_custom,
                          onTap: () => setState(() => _custom = false),
                        ),
                        _GoalModeButton(
                          label: 'กลุ่มตั้งเอง',
                          selected: _custom,
                          onTap: () => setState(() => _custom = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSpace3),
                  if (!_custom)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(kSpace4),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(kRadiusCard),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_systemGoal.toStringAsFixed(0)} ชม.',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(height: kSpace1),
                          Text(
                            'คำนวณจาก $_peopleCount คน × $_days วัน '
                            '(ประมาณ $_kSuggestHoursPerPersonDay ชม./คน/วัน) '
                            '— เปลี่ยนจำนวนวันหรือคน เป้าจะปรับตาม',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: kInkSoft),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _StepperCard(
                      value: '${_goal.toStringAsFixed(0)} ชม.',
                      caption: 'เป้ารวมของทั้งกลุ่ม',
                      canDec: _goal > _minGoal,
                      canInc: _goal < _maxGoal,
                      decLabel: 'ลดเป้าหมาย 1 ชั่วโมง',
                      incLabel: 'เพิ่มเป้าหมาย 1 ชั่วโมง',
                      onDec: () => setState(() => _goal -= 1),
                      onInc: () => setState(() => _goal += 1),
                    ),
                    const SizedBox(height: kSpace2),
                    _PresetChips(
                      values: _goalPresets,
                      selected: _goal.round(),
                      unit: 'ชม.',
                      onPick: (v) => setState(() => _goal = v.toDouble()),
                    ),
                  ],
                  const SizedBox(height: kSpace5),

                  // ภายในกี่วัน
                  const _SheetHeading('ภายในกี่วัน'),
                  const SizedBox(height: kSpace3),
                  _StepperCard(
                    value: '$_days วัน',
                    caption: _days == widget.durationDays
                        ? 'เหลืออีก ${widget.daysLeft} วัน'
                        : 'เปลี่ยนจำนวนวัน = เริ่มนับวันใหม่ตั้งแต่วันที่บันทึก',
                    canDec: _days > _minDays,
                    canInc: _days < _maxDays,
                    decLabel: 'ลดจำนวนวัน',
                    incLabel: 'เพิ่มจำนวนวัน',
                    onDec: () => setState(() => _days -= 1),
                    onInc: () => setState(() => _days += 1),
                  ),
                  const SizedBox(height: kSpace2),
                  _PresetChips(
                    values: _dayPresets,
                    selected: _days,
                    unit: 'วัน',
                    onPick: (v) => setState(() => _days = v),
                  ),
                  const SizedBox(height: kSpace5),

                  // ใครช่วยสะสม
                  _SheetHeading(
                    'ใครช่วยสะสมบ้าง',
                    subtitle:
                        'แตะเพื่อเลือกเพื่อนที่ร่วมชาเลนจ์ · ตอนนี้ร่วม $_peopleCount คน (รวมคุณ) '
                        '· คนที่ซ่อนเวลา ยังนับรวมในเป้าทีม แต่ไม่แสดงรายคน',
                  ),
                  const SizedBox(height: kSpace3),
                  for (final m in members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: kSpace2),
                      child: _MemberRow(
                        member: m,
                        joined: m.isMe || _people.contains(m.code),
                        maxMinutes: maxMinutes,
                        onToggle: m.isMe ? null : () => _togglePerson(m.code!),
                      ),
                    ),
                  const SizedBox(height: kSpace3),
                  const Text(
                    'นับเฉพาะเวลาที่โฟกัสในแอป (ไม่นับช่วงพัก) · นับตั้งแต่วันที่เริ่มชาเลนจ์',
                    style: TextStyle(fontSize: 13, color: kInkSoft),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, kSpace2, kGutter, kSpace4),
              child: PressableScale(
                onTap: () {
                  widget.onApply(_effectiveGoal, _custom, _days, Set.of(_people));
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: kSpace4),
                  decoration: BoxDecoration(
                    color: kBrand,
                    borderRadius: BorderRadius.circular(kRadiusChip),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'บันทึกชาเลนจ์',
                    style: TextStyle(
                      // ขาวบน kBrand = ข้อยกเว้นตั้งใจของผู้ใช้ (ดู theme.dart)
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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

class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: kSpace1),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: kInkSoft),
          ),
        ],
      ],
    );
  }
}

/// แถวสมาชิกในชาเลนจ์: แตะเพื่อเลือก/เอาออก (ตัวเราร่วมเสมอ จึงกดไม่ได้)
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.joined,
    required this.maxMinutes,
    required this.onToggle,
  });

  final _Member member;
  final bool joined;
  final int maxMinutes;
  final VoidCallback? onToggle; // null = กดไม่ได้ (ตัวเรา)

  @override
  Widget build(BuildContext context) {
    final Widget middle;
    if (!joined) {
      middle = const Text(
        'ไม่ร่วมชาเลนจ์',
        style: TextStyle(fontSize: 13, color: kInkSoft),
      );
    } else if (member.hidden) {
      middle = const Row(
        children: [
          Icon(CupertinoIcons.lock_fill, size: 13, color: kInkFaint),
          SizedBox(width: kSpace1),
          Text(
            'ซ่อนเวลา · นับรวมในทีม',
            style: TextStyle(fontSize: 13, color: kInkSoft),
          ),
        ],
      );
    } else {
      middle = Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kSpace1),
              child: Stack(
                children: [
                  Container(height: kSpace2, color: kSurfaceAlt),
                  FractionallySizedBox(
                    widthFactor: member.minutes / maxMinutes,
                    child: Container(height: kSpace2, color: kBrand),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: kSpace3),
          Text(
            formatMinutes(member.minutes),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kInk,
            ),
          ),
        ],
      );
    }

    final row = Container(
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: joined ? 1 : 0.5,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: member.bg,
              child: Text(
                member.name.characters.first,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
            ),
          ),
          const SizedBox(width: kSpace3),
          SizedBox(
            width: 56,
            child: Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: joined ? kInk : kInkSoft,
              ),
            ),
          ),
          Expanded(child: middle),
          const SizedBox(width: kSpace3),
          Icon(
            joined
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            // ตัวเรา = ร่วมเสมอ → จางลงให้รู้ว่ากดเปลี่ยนไม่ได้
            color: !joined
                ? kInkFaint
                : (onToggle == null ? kInkFaint : kBrand),
            size: 24,
          ),
        ],
      ),
    );

    if (onToggle == null) return row;
    return PressableScale(
      onTap: onToggle!,
      child: Semantics(
        button: true,
        selected: joined,
        label: 'ให้${member.name}ร่วมชาเลนจ์',
        excludeSemantics: true,
        child: row,
      ),
    );
  }
}

class _GoalModeButton extends StatelessWidget {
  const _GoalModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: kDurQuick,
          curve: kCurveSmooth,
          padding: const EdgeInsets.symmetric(vertical: kSpace3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBrandFill : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusChip),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? kInk : kInkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// การ์ดปรับค่าด้วยปุ่ม − / + (ตัวเลขใหญ่ตรงกลาง + คำอธิบายเล็ก)
class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.value,
    required this.caption,
    required this.canDec,
    required this.canInc,
    required this.decLabel,
    required this.incLabel,
    required this.onDec,
    required this.onInc,
  });

  final String value;
  final String caption;
  final bool canDec;
  final bool canInc;
  final String decLabel;
  final String incLabel;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: CupertinoIcons.minus,
            label: decLabel,
            enabled: canDec,
            onTap: onDec,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: kInkSoft),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: CupertinoIcons.add,
            label: incLabel,
            enabled: canInc,
            onTap: onInc,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label; // สำหรับ screen reader
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: enabled,
      onTap: onTap,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? kBrandFill : kSurfaceAlt,
            borderRadius: BorderRadius.circular(kRadiusChip),
          ),
          child: Icon(icon, size: 20, color: enabled ? kInk : kInkFaint),
        ),
      ),
    );
  }
}

/// ชิปตัวเลือกด่วน (เช่น 3 / 7 / 14 / 30 วัน) — ตัวที่ตรงกับค่าปัจจุบันจะถูกเน้น
class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.values,
    required this.selected,
    required this.unit,
    required this.onPick,
  });

  final List<int> values;
  final int selected;
  final String unit;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: kSpace2),
          Expanded(
            child: PressableScale(
              onTap: () => onPick(values[i]),
              child: Semantics(
                button: true,
                selected: values[i] == selected,
                label: '${values[i]} $unit',
                excludeSemantics: true,
                child: AnimatedContainer(
                  duration: kDurQuick,
                  curve: kCurveSmooth,
                  padding: const EdgeInsets.symmetric(vertical: kSpace3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: values[i] == selected ? kBrandFill : kSurface,
                    borderRadius: BorderRadius.circular(kRadiusChip),
                  ),
                  child: Text(
                    '${values[i]} $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: values[i] == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: values[i] == selected ? kInk : kInkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet: เพิ่มเพื่อน — กรอกแค่ "รหัสเพื่อน" (ARN-xxxx) · ส่งคำขอ → เพื่อนต้องกดยืนยัน
// ---------------------------------------------------------------------------

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet({
    required this.existingCodes,
    required this.pendingCodes,
    required this.onSend,
  });

  final Set<String> existingCodes;
  final Set<String> pendingCodes;
  final ValueChanged<String> onSend;

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

enum _LookupState { idle, found, self, already, invalid }

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _controller = TextEditingController();
  _LookupState _state = _LookupState.idle;
  String _code = '';
  bool _sent = false;
  bool _copied = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final raw = _controller.text.trim().toUpperCase();
    final code = raw.startsWith('ARN-') || raw.isEmpty ? raw : 'ARN-$raw';
    setState(() {
      _code = code;
      _sent = widget.pendingCodes.contains(code);
      if (!RegExp(r'^ARN-\d{4}$').hasMatch(code)) {
        _state = _LookupState.invalid;
      } else if (code == kMyFriendCode) {
        _state = _LookupState.self;
      } else if (widget.existingCodes.contains(code)) {
        _state = _LookupState.already;
      } else {
        _state = _LookupState.found; // TODO: ค้นหาจริงจาก backend
      }
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: kMyFriendCode));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kGutter, kSpace5, kGutter, kSpace4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เพิ่มเพื่อน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: kSpace1),
              const Text(
                'กรอกแค่รหัสเพื่อน (เช่น ARN-1234) แล้วส่งคำขอ — เพื่อนต้องกดยืนยันก่อน ถึงจะเห็นกันและกัน',
                style: TextStyle(fontSize: 13, color: kInkSoft),
              ),
              const SizedBox(height: kSpace4),

              // รหัสของฉัน
              Container(
                padding: const EdgeInsets.all(kSpace4),
                decoration: BoxDecoration(
                  color: kBrandFillSoft,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รหัสเพื่อนของฉัน',
                            style: TextStyle(fontSize: 13, color: kInk),
                          ),
                          SizedBox(height: 2),
                          Text(
                            kMyFriendCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PressableScale(
                      onTap: _copy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpace3,
                          vertical: kSpace2,
                        ),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(kRadiusChip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied
                                  ? CupertinoIcons.checkmark_alt
                                  : CupertinoIcons.doc_on_doc,
                              size: 16,
                              color: kInk,
                            ),
                            const SizedBox(width: kSpace1),
                            Text(
                              _copied ? 'คัดลอกแล้ว' : 'คัดลอก',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpace5),

              const Text(
                'ค้นหาจากรหัสเพื่อน',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: kSpace2),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(kRadiusChip),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        onChanged: (_) {
                          if (_state != _LookupState.idle) {
                            setState(() => _state = _LookupState.idle);
                          }
                        },
                        style: const TextStyle(color: kInk, fontSize: 15),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            CupertinoIcons.person_add,
                            color: kInkSoft,
                            size: 18,
                          ),
                          hintText: 'ARN-0000',
                          hintStyle: TextStyle(color: kDoneGrey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpace2),
                  PressableScale(
                    onTap: _search,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: kSpace4),
                      decoration: BoxDecoration(
                        color: kBrandFill,
                        borderRadius: BorderRadius.circular(kRadiusChip),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ค้นหา',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpace3),
              _buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    switch (_state) {
      case _LookupState.idle:
        return const SizedBox.shrink();
      case _LookupState.invalid:
        return _notice(
          CupertinoIcons.exclamationmark_circle_fill,
          kPinkFill,
          'รูปแบบรหัสไม่ถูกต้อง ลองใหม่เป็น ARN- ตามด้วยตัวเลข 4 หลัก',
        );
      case _LookupState.self:
        return _notice(
          CupertinoIcons.info_circle_fill,
          kYellowFill,
          'นี่คือรหัสของคุณเอง ส่งรหัสนี้ให้เพื่อนเพื่อให้เขาเพิ่มคุณ',
        );
      case _LookupState.already:
        return _notice(
          CupertinoIcons.checkmark_circle_fill,
          kMintFill,
          'เป็นเพื่อนกันอยู่แล้ว',
        );
      case _LookupState.found:
        return Container(
          padding: const EdgeInsets.all(kSpace3),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: kLavenderFill,
                child: Icon(CupertinoIcons.person_fill, color: kInk, size: 22),
              ),
              const SizedBox(width: kSpace3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _code,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    const Text(
                      'พบผู้ใช้นี้',
                      style: TextStyle(fontSize: 13, color: kInkSoft),
                    ),
                  ],
                ),
              ),
              PressableScale(
                enabled: !_sent,
                onTap: () {
                  widget.onSend(_code);
                  setState(() => _sent = true);
                },
                child: AnimatedContainer(
                  duration: kDurQuick,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpace3,
                    vertical: kSpace2,
                  ),
                  decoration: BoxDecoration(
                    color: _sent ? kMintFill : kBrand,
                    borderRadius: BorderRadius.circular(kRadiusChip),
                  ),
                  child: Text(
                    _sent ? 'ส่งคำขอแล้ว' : 'ส่งคำขอ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      // ขาวบน kBrand = ข้อยกเว้นของผู้ใช้ · ส่งแล้ว = พื้นมิ้นต์ + ข้อความเข้ม
                      color: _sent ? kInk : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _notice(IconData icon, Color bg, String text) {
    return Container(
      padding: const EdgeInsets.all(kSpace3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kInk),
          const SizedBox(width: kSpace2),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: kInk)),
          ),
        ],
      ),
    );
  }
}