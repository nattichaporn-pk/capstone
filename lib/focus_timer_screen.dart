import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart'
    show CupertinoIcons, CupertinoPicker, CupertinoSwitch;
import 'package:flutter/material.dart';

import 'bottom_nav.dart'; // หรือ bottom_nav_pkg.dart (BottomNavPkg) — API เหมือนกัน
import 'pressable.dart';
import 'theme.dart';

enum TimerPhase { focus, breakPhase }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  static const int _focusTabIndex = 2;

  Duration _focusDuration = const Duration(minutes: 25);
  late Duration _remaining = _focusDuration;
  Timer? _ticker;
  bool _isRunning = false;
  bool _showTime = true;

  TimerPhase _currentPhase = TimerPhase.focus;
  int _selectedPresetMinutes = 25;
  final int _totalRounds = 4;
  int _currentRound = 1;

  int _customHours = 0;
  int _customMinutes = 25;
  int _customSeconds = 0;

  bool _customExpanded = false; // การ์ด "กำหนดเอง" พับไว้ก่อน (เหมือนการ์ดพักหลังจบรอบ)
  bool _breakExpanded = false;
  int _breakMinutes = 5;

  // controller ของ wheel เก็บใน state (เดิมสร้างใหม่ทุก build = ทุกวินาทีที่นาฬิกาเดิน → wheel สะดุด/รีเซ็ต)
  late FixedExtentScrollController _hCtrl =
      FixedExtentScrollController(initialItem: _customHours);
  late FixedExtentScrollController _mCtrl =
      FixedExtentScrollController(initialItem: _customMinutes);
  late FixedExtentScrollController _sCtrl =
      FixedExtentScrollController(initialItem: _customSeconds);
  late final FixedExtentScrollController _breakCtrl =
      FixedExtentScrollController(initialItem: _breakMinutes);
  int _wheelEpoch = 0; // เปลี่ยนเมื่อ preset เขียนทับค่า → rebuild wheel ด้วย controller ใหม่

  late final AnimationController _flameController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // เคารพ reduced-motion: ปิดเปลวไฟกะพริบ
    if (MediaQuery.disableAnimationsOf(context)) {
      _flameController.stop();
    } else if (!_flameController.isAnimating) {
      _flameController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flameController.dispose();
    _hCtrl.dispose();
    _mCtrl.dispose();
    _sCtrl.dispose();
    _breakCtrl.dispose();
    super.dispose();
  }

  void _toggleRunning() {
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds <= 0) {
          _handlePhaseComplete();
          return;
        }
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      });
    } else {
      _ticker?.cancel();
    }
  }

  void _handlePhaseComplete() {
    if (_currentPhase == TimerPhase.focus) {
      setState(() {
        _currentPhase = TimerPhase.breakPhase;
        _remaining = Duration(minutes: _breakMinutes);
      });
    } else {
      if (_currentRound < _totalRounds) {
        setState(() {
          _currentRound++;
          _currentPhase = TimerPhase.focus;
          _remaining = _focusDuration;
        });
      } else {
        _ticker?.cancel();
        setState(() {
          _isRunning = false;
          _currentPhase = TimerPhase.focus;
          _currentRound = 1;
          _remaining = _focusDuration;
        });
      }
    }
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = TimerPhase.focus;
      _currentRound = 1;
      _remaining = _focusDuration;
    });
  }

  void _applyPreset(int minutes) {
    _ticker?.cancel();
    final old = [_hCtrl, _mCtrl, _sCtrl];
    setState(() {
      _selectedPresetMinutes = minutes;
      _isRunning = false;
      _focusDuration = Duration(minutes: minutes);
      _currentPhase = TimerPhase.focus;
      _currentRound = 1;
      _remaining = _focusDuration;
      _customHours = 0;
      _customMinutes = minutes;
      _customSeconds = 0;
      // ให้ wheel "กำหนดเอง" ขยับตาม preset
      _hCtrl = FixedExtentScrollController(initialItem: _customHours);
      _mCtrl = FixedExtentScrollController(initialItem: _customMinutes);
      _sCtrl = FixedExtentScrollController(initialItem: _customSeconds);
      _wheelEpoch++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in old) {
        c.dispose();
      }
    });
  }

  void _applyCustomDuration() {
    final newDuration = Duration(
      hours: _customHours,
      minutes: _customMinutes,
      seconds: _customSeconds,
    );
    if (newDuration.inSeconds <= 0) return;
    _ticker?.cancel();
    setState(() {
      _selectedPresetMinutes = -1;
      _isRunning = false;
      _focusDuration = newDuration;
      _currentPhase = TimerPhase.focus;
      _currentRound = 1;
      _remaining = newDuration;
    });
  }

  String get _timeLabel {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _burnProgress {
    final total = _currentPhase == TimerPhase.focus
        ? _focusDuration.inSeconds
        : (_breakMinutes * 60);
    if (total <= 0) return 0;
    final elapsed = total - _remaining.inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
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
                  title: 'ตั้งเวลาโฟกัส',
                  onBack: () => Navigator.of(context).maybePop(),
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
                      const SizedBox(height: kSpace3),
                      _buildPhaseBadges(),
                      const SizedBox(height: kSpace5),
                      Center(child: _buildVisualIndicator()),
                      const SizedBox(height: kSpace6),
                      Center(child: _buildTimeText()),
                      const SizedBox(height: kSpace3),
                      Center(child: _buildRoundDots()),
                      const SizedBox(height: kSpace4),
                      Center(child: _buildShowTimeToggle()),
                      const SizedBox(height: kSpace6),
                      _buildPauseResetButtons(),
                      const SizedBox(height: kSpace8),
                      const Text(
                        'ระยะเวลา',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: kSpace3),
                      _buildPresetRow(),
                      const SizedBox(height: kSpace4),
                      _buildCustomWheelPicker(),
                      const SizedBox(height: kSpace4),
                      _buildBreakCard(),
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

  // ---- Phase badges -----------------------------------------------------

  Widget _phaseBadge({
    required String label,
    required bool active,
    required Color activeBg,
    required Color activeFg,
  }) {
    return AnimatedContainer(
      duration: kDurQuick,
      curve: kCurveSmooth,
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: 6),
      decoration: BoxDecoration(
        color: active ? activeBg : kSurfaceAlt,
        borderRadius: BorderRadius.circular(kRadiusChip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: active ? activeFg : kInkSoft,
        ),
      ),
    );
  }

  Widget _buildPhaseBadges() {
    final isFocus = _currentPhase == TimerPhase.focus;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _phaseBadge(
          label: 'โฟกัส',
          active: isFocus,
          activeBg: kBrandFill,
          activeFg: kInk,
        ),
        const SizedBox(width: kSpace3),
        _phaseBadge(
          label: 'พัก',
          active: !isFocus,
          activeBg: kMintFill,
          activeFg: kInk,
        ),
      ],
    );
  }

  // ---- Visual indicator ---------------------------------------------------

  Widget _buildVisualIndicator() {
    if (_currentPhase == TimerPhase.breakPhase) {
      return Container(
        width: 180,
        height: 180,
        decoration: const BoxDecoration(
          color: kMintFill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.coffee, size: 64, color: kInk),
      );
    }
    return _buildRealisticCandle();
  }

  Widget _buildRealisticCandle() {
    const double maxCandleHeight = 110;
    const double minCandleHeight = 30;
    final double currentHeight =
        maxCandleHeight - ((maxCandleHeight - minCandleHeight) * _burnProgress);

    return Container(
      width: 180,
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 20),
      child: AnimatedBuilder(
        animation: _flameController,
        builder: (context, _) {
          final flicker = _flameController.value;
          final scale = 0.95 + (flicker * 0.05);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // เปลวไฟ
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: 60 + (flicker * 10),
                      height: 60 + (flicker * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87, // ไส้เทียน
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipPath(
                          clipper: _FlameClipper(),
                          child: Container(
                            width: 24,
                            height: 40,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0, 0.5),
                                radius: 0.6,
                                colors: [Colors.orange, Colors.redAccent],
                              ),
                            ),
                          ),
                        ),
                        ClipPath(
                          clipper: _FlameClipper(),
                          child: Container(
                            width: 16,
                            height: 28,
                            decoration: const BoxDecoration(color: Color(0xFFFFD54F)),
                          ),
                        ),
                        ClipPath(
                          clipper: _FlameClipper(),
                          child: Container(
                            width: 8,
                            height: 16,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.lightBlueAccent, Colors.white],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ตัวเทียน — AnimatedContainer 1 วินาที (linear) ให้ความสูงลดลงสมูทตามนาฬิกา ตั้งใจไม่ใช้ kDur*
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.linear,
                width: 54,
                height: currentHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFF8B0000)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(kSpace1),
                          bottomRight: Radius.circular(kSpace1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      child: Container(
                        width: 44,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // หยดน้ำตาเทียน หดตามความสูง
                    Positioned(
                      left: 1,
                      top: 2,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        width: 6,
                        height: (currentHeight * 0.35).clamp(10.0, 35.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(kSpace1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 5,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        width: 8,
                        height: (currentHeight * 0.45).clamp(15.0, 45.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(kSpace1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        width: 54,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFB53B), // ฐานเทียน
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- Time / rounds / toggle ---------------------------------------------

  Widget _buildTimeText() {
    return Text(
      _showTime ? _timeLabel : '••••',
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: kInk,
        letterSpacing: 2,
        fontFeatures: [FontFeature.tabularFigures()], // ตัวเลขกว้างเท่ากัน ไม่สั่นตอนนับถอยหลัง
      ),
    );
  }

  Widget _buildRoundDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentPhase == TimerPhase.focus
              ? 'รอบโฟกัสที่ $_currentRound'
              : 'ช่วงพักผ่อน',
          style: const TextStyle(
            fontSize: 14,
            color: kInkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: kSpace3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_totalRounds, (i) {
            final active = i < _currentRound;
            return AnimatedContainer(
              duration: kDurQuick,
              margin: const EdgeInsets.symmetric(horizontal: kSpace1),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? kPink : kHairline,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildShowTimeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'แสดงเวลา',
          style: TextStyle(
            fontSize: 14,
            color: kInkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: kSpace2),
        CupertinoSwitch(
          value: _showTime,
          activeTrackColor: kBrand,
          onChanged: (v) => setState(() => _showTime = v),
        ),
      ],
    );
  }

  // ---- Buttons ------------------------------------------------------------

  Widget _buildPauseResetButtons() {
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: _toggleRunning,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kBrand, // ปุ่มสีหลัก
                borderRadius: BorderRadius.circular(kRadiusChip),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRunning
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_arrow_solid,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: kSpace2),
                  Text(
                    _isRunning ? 'หยุดชั่วคราว' : 'เริ่ม',
                    style: const TextStyle(
                      // ขาวบน kBrand = ข้อยกเว้นของผู้ใช้ (เหมือนปุ่ม "เริ่มโฟกัส")
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
        const SizedBox(width: kSpace3),
        Expanded(
          child: PressableScale(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kBrandFillSoft,
                borderRadius: BorderRadius.circular(kRadiusChip),
              ),
              alignment: Alignment.center,
              child: const Text(
                'รีเซ็ต',
                style: TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Presets / custom wheel ----------------------------------------------

  Widget _buildPresetRow() {
    const presets = [15, 25, 45];
    return Row(
      children: [
        for (var i = 0; i < presets.length; i++) ...[
          if (i > 0) const SizedBox(width: kSpace2),
          Expanded(child: _presetChip(presets[i])),
        ],
      ],
    );
  }

  Widget _presetChip(int minutes) {
    final selected = _selectedPresetMinutes == minutes;
    return PressableScale(
      onTap: () => _applyPreset(minutes),
      child: AnimatedContainer(
        duration: kDurQuick,
        curve: kCurveSmooth,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kNavYellow : kSurface, // ชิปที่เลือก = เหลือง + ข้อความเข้ม
          borderRadius: BorderRadius.circular(kRadiusCard),
          boxShadow: selected ? null : kCardShadow,
        ),
        child: Text(
          '$minutes นาที',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: kInk,
          ),
        ),
      ),
    );
  }

  // "25 นาที" · "1 ชม. 30 น." · "1 ชม. 5 น. 20 วิ."
  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    final parts = <String>[
      if (h > 0) '$h ชม.',
      if (m > 0) '$m น.',
      if (sec > 0) '$sec วิ.',
    ];
    if (parts.isEmpty) return '0 วิ.';
    if (h == 0 && sec == 0) return '$m นาที';
    return parts.join(' ');
  }

  Widget _buildCustomWheelPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow,
      ),
      child: AnimatedSize(
        duration: kDurBase,
        curve: kCurveSmooth,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            PressableScale(
              onTap: () => setState(() => _customExpanded = !_customExpanded),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kNavYellow,
                      borderRadius: BorderRadius.circular(kRadiusChip),
                    ),
                    child: const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: kInkOnYellow,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: kSpace4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กำหนดเอง',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: kInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ปรับเวลาโฟกัสเองเป็น ชม./นาที/วินาที',
                          style: TextStyle(fontSize: 13, color: kInkSoft),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpace2,
                      vertical: kSpace1,
                    ),
                    decoration: BoxDecoration(
                      color: kYellowFill,
                      borderRadius: BorderRadius.circular(kSpace2),
                    ),
                    child: Text(
                      _durationLabel(_focusDuration),
                      style: const TextStyle(
                        color: kInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpace2),
                  Icon(
                    _customExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: kInkSoft,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_customExpanded) ...[
              const SizedBox(height: kSpace2),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    _wheelColumn(
                      key: ValueKey('h$_wheelEpoch'),
                      controller: _hCtrl,
                      itemCount: 24,
                      label: 'ชม.',
                      onChanged: (v) {
                        _customHours = v;
                        _applyCustomDuration();
                      },
                    ),
                    _wheelColumn(
                      key: ValueKey('m$_wheelEpoch'),
                      controller: _mCtrl,
                      itemCount: 60,
                      label: 'นาที',
                      onChanged: (v) {
                        _customMinutes = v;
                        _applyCustomDuration();
                      },
                    ),
                    _wheelColumn(
                      key: ValueKey('s$_wheelEpoch'),
                      controller: _sCtrl,
                      itemCount: 60,
                      label: 'วิ.',
                      onChanged: (v) {
                        _customSeconds = v;
                        _applyCustomDuration();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wheelColumn({
    required Key key,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Stack(
        key: key,
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
            itemExtent: 32,
            scrollController: controller,
            onSelectedItemChanged: onChanged,
            selectionOverlay: const SizedBox.shrink(),
            children: List.generate(
              itemCount,
              (i) => Center(
                child: Text(
                  i.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: kInkSoft),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Break card -----------------------------------------------------------

  Widget _buildBreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCardShadow,
      ),
      child: AnimatedSize(
        duration: kDurBase,
        curve: kCurveSmooth,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            PressableScale(
              onTap: () => setState(() => _breakExpanded = !_breakExpanded),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kMintFill,
                      borderRadius: BorderRadius.circular(kRadiusChip),
                    ),
                    child: const Icon(Icons.coffee, color: kInk, size: 22),
                  ),
                  const SizedBox(width: kSpace4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'พักหลังจบรอบ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: kInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ทำงานเสร็จจะเข้าสู่ช่วงพัก',
                          style: TextStyle(fontSize: 13, color: kInkSoft),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpace2,
                      vertical: kSpace1,
                    ),
                    decoration: BoxDecoration(
                      color: kMintFill,
                      borderRadius: BorderRadius.circular(kSpace2),
                    ),
                    child: Text(
                      '$_breakMinutes นาที',
                      style: const TextStyle(
                        color: kInk, // พื้นพาสเทล → ข้อความเข้ม
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpace2),
                  Icon(
                    _breakExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: kInkSoft,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_breakExpanded) ...[
              const SizedBox(height: kSpace2),
              SizedBox(
                height: 100,
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: _breakCtrl,
                  onSelectedItemChanged: (v) {
                    setState(() => _breakMinutes = v == 0 ? 1 : v);
                  },
                  children: List.generate(
                    60,
                    (i) => Center(
                      child: Text(
                        '$i นาที',
                        style: const TextStyle(fontSize: 15, color: kInk),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header + title row
// ---------------------------------------------------------------------------

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

class _FlameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(size.width, size.height * 0.4, size.width / 2, size.height);
    path.quadraticBezierTo(0, size.height * 0.4, size.width / 2, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}