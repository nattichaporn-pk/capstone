import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

// ความกว้างสูงสุดของการ์ดแอป — บนจอกว้าง (เช่นเปิดเว็บบนคอม) จะไม่ยืดเต็มจอ
// แต่จะดูเหมือนแอปมือถือวางอยู่กึ่งกลาง เหมือน Figma design ต้นแบบ
const double kMaxContentWidth = 480;

// ===== พาเลตต์สี — พาสเทลสบายตา + accent เข้มไว้อ่าน =====
// สเปกเต็ม + ผลตรวจ WCAG ทุกคู่: docs/design-system/student_task_app/MASTER.md §1.1
// หลักการ: พื้นผิว = พาสเทล/โทนอุ่น · ข้อความ+เส้นที่ต้องอ่านออก = โทนเข้ม
// พาสเทลใช้เป็น "พื้น" ที่มีข้อความเข้มทับเท่านั้น — ห้ามเป็นสีข้อความ/สีเส้น

// -- พื้น / พื้นผิว (2026-09-08: กลับมาเป็น "ขาว" สไตล์ iOS ตามที่ผู้ใช้ขอ — เลิกโทนอุ่น) --
const kPageWarm = Color(
  0xFFFFFFFF,
); // พื้นหน้าทุกหน้า — ขาว (iOS systemBackground) · การ์ด/แถวแยกด้วยเงา/เส้น
// 2026-09-29: พื้นหน้า "AI Study" เท่านั้น — ผู้ใช้ขอสีอุ่น FAF9F6 กลับมาเฉพาะหน้านี้ (หน้าอื่นยังขาว kPageWarm
// เหมือนเดิม ไม่ได้ขอเปลี่ยนทั้งแอป) ชื่อ token คล้าย kPageWarm ตอนที่ยังเป็นสีนี้ก่อน 2026-09-08
const kPageWarmAiStudy = Color(0xFFFAF9F6); // kInkFaint บนนี้ 3.28:1 ผ่านเกณฑ์ UI 3:1 ที่เหลือผ่านสบายๆเหมือนขาว
const kSurface = Color(0xFFFFFFFF); // การ์ด/dialog/ชิปเมนู active — = พื้นหน้า → การ์ดต้องมี kCardShadow หรือเส้น เสมอ
const kSurfaceAlt = Color(
  0xFFF2F2F7,
); // พื้นรอง/inset/พื้นชีต grouped-list (iOS systemGroupedBackground)
const kFieldFill = Color(
  0xFFF1F1F5,
); // พื้น TextField/Dropdown (ข้อความ #1F2937 ≈ 13:1)
const kHairline = Color(
  0xFFE4E4E8,
); // เส้นคั่น/กริดปฏิทิน — เทากลาง decorative (เดิมน้ำตาลอุ่น)
const kOutline = Color(0xFFE5E7EB); // เส้น/ขอบ ของการ์ด/ชีต

// -- ข้อความ / ไอคอน (ผ่านบนพื้นอุ่นหมด) --
const kInk = Color(0xFF1A1A1A); // ข้อความหลัก (15.97:1 บนพื้นอุ่น)
const kInkSoft = Color(0xFF5B6472); // ข้อความรอง/ไอคอนรอง (5.49:1)
const kInkFaint = Color(
  0xFF8A8A8A,
); // ป้ายจาง/ขอบ checkbox ปกติ (3.17:1 — เกณฑ์ UI 3:1)
const kInkOnYellow = Color(
  0xFF3D3200,
); // ข้อความ/ไอคอนบนพื้นเหลืองทุกเฉด (kNavYellow 9.98:1)
const kDoneGrey = Color(0xFF6B7280); // งานเสร็จ (ขีดฆ่า), hint ใน TextField

// -- Accent: น้ำเงิน --
const kBrand = Color(
  0xFF5AA9E6,
); // สีฟังก์ชันหลัก: FAB/ปุ่ม/ลิงก์/focus ring/สิ่งที่เลือก/วันนี้ — 2026-09-22 ผู้ใช้ขอเปลี่ยนตรงๆเป็นโค้ดนี้ (= kSky เดิม)
// ⚠️ ขาวบนนี้ = 2.54:1 fail AA (เดิม kBrand #072AC8 ผ่าน 9.66:1) — ข้อยกเว้นตั้งใจของผู้ใช้ เหมือน kSky ใน ai_study_page.dart
// ห้ามมีคนแก้กลับเป็นสีเข้มโดยอ้าง WCAG อีก เว้นแต่ผู้ใช้ขอเอง
const kBrandBright = Color(
  0xFF1E96FC,
); // ตกแต่ง/gradient/ข้อความใหญ่ — ห้ามเป็นข้อความ/ไอคอนเล็กบนพื้นอุ่น (2.82:1)
const kBrandFill = Color(
  0xFF7FC8F8,
); // พื้นเน้น + ข้อความเข้ม (ชิปเลือก/ไฮไลต์วันนี้) — kBrand 5.30:1
const kBrandFillSoft = Color(
  0xFFA2D6F9,
); // พื้นจาง/gradient start/hover — kInk 11.21:1, kBrand 6.22:1
const kSky = Color(
  0xFF5AA9E6,
); // พื้นตกแต่งชิ้นใหญ่เท่านั้น — รับได้แค่ข้อความเข้มขนาดใหญ่

// -- Accent: โทนอุ่น --
const kNavYellow = Color(0xFFFFE45E); // (เดิม: พื้นแถบเมนู — ตอนนี้ pill เป็น glass แล้ว เก็บ token ไว้เผื่อ badge)
const kSunDeep = Color(
  0xFFFFC600,
); // พื้น badge/ไฮไลต์โทนทอง + ข้อความเข้ม — ห้ามเป็นเส้น
const kPink = Color(
  0xFFFF6392,
); // accent สนุก เป็นพื้น + ข้อความเข้ม — ห้ามข้อความขาว/เส้นบาง (kInk 6.18:1)

// -- Accent เสริม (2026-10-15: ผู้ใช้ขอ "ไม่ต้องขาวดำขนาดนั้น") --
// ใช้เป็น "พื้น" พาสเทลที่มีข้อความ/ไอคอนเข้ม (kInk) ทับ — ทุกคู่ kInk ≥ 11:1
// kSuccess / kFlame / kGold = สีไอคอน/จุดสถานะเท่านั้น (ไม่ใช้เป็นสีข้อความเล็ก)
const kMintFill = Color(0xFFCDEFD8); // พื้นเขียวมิ้นต์ — ช่วงพัก / ออนไลน์ / สำเร็จ
const kYellowFill = Color(0xFFFFF1B8); // พื้นเหลืองอ่อน — ชาเลนจ์ / ไฮไลต์
const kPeachFill = Color(0xFFFFDCC7); // พื้นพีช — streak / ไฟ
const kPinkFill = Color(0xFFFFD6E0); // พื้นชมพูอ่อน — กำลังใจ / ถูกใจ
const kLavenderFill = Color(0xFFE0DBF8); // พื้นม่วงอ่อน — สลับสีอวตาร/ไอคอน
const kSuccess = Color(0xFF34C759); // จุดออนไลน์ / สำเร็จ (iOS green)
const kFlame = Color(0xFFFF8A00); // ไอคอนไฟ streak
const kGold = Color(0xFFE0A800); // ไอคอนถ้วย/ตรา

// -- Danger --
const kDanger = Color(
  0xFFFF6392,
); // error/urgent/homework — 2026-09-22 ผู้ใช้ขอเปลี่ยนจากแดง #D02648 ตรงๆ เป็นโค้ดนี้ (= kPink เดิม)
// ⚠️ ข้อความบนพื้นขาว 2.82:1 / ขาวบนพื้นนี้ 2.82:1 / บนพื้น kDangerBg 2.58:1 — ทั้งหมด fail AA (เดิม 4.75–5.18 ผ่าน)
// ข้อยกเว้นตั้งใจของผู้ใช้ เหมือน kBrand/kSky — ห้ามแก้กลับโดยอ้าง WCAG เว้นแต่ผู้ใช้ขอเอง
const kDangerBg = Color(
  0xFFFEF2F2,
); // พื้นการ์ด urgent (kDanger 4.74:1, kInk 15.9:1, kInkSoft 5.47:1)
const kDoneBg = Color(0xFFF0F1F3); // พื้นการ์ดงานที่เสร็จแล้ว

// -- Gradient (สีรอง — เส้น/แถบ/วงแหวน ตกแต่งเท่านั้น ห้ามมีข้อความทับเว้นแต่ผ่านทุก stop) --
const kGradBlue = [Color(0xFFA2D6F9), Color(0xFF1E96FC), Color(0xFF072AC8)];
const kGradSunset = [
  Color(0xFFFFC600),
  Color(0xFFFF6392),
]; // วงแหวนโฟกัสไทเมอร์ (แท็บ Focus)

// -- Aliases เดิม: ยังไม่ได้ migrate ทั้ง repo (main.dart / ชีต ยังอ้างชื่อเก่า) --
// ตารางเปลี่ยนชื่อเต็ม: MASTER.md §7. ค่อยลบ alias เมื่อ migrate แต่ละไฟล์เสร็จ.
const kBrandBlue = kBrand;
const kBrandBlueSoft = kBrandBright;
const kSheetBg =
    kSurfaceAlt; // พื้นชีต = เทาอ่อน iOS grouped-list (การ์ดขาวลอยบนนี้)
const kPageOuter =
    kSurfaceAlt; // พื้นรอบนอกจอกว้าง = เทาอ่อน (ให้เห็นกรอบ 480 บนเดสก์ท็อป)

// ระยะขอบซ้าย-ขวามาตรฐานของ "เนื้อหาหน้า" ทุกหน้า (ปฏิทิน + To do list ใช้ค่าเดียวกัน = 8pt grid / iOS content margin)
const double kGutter = 16;

// ===== แถบเมนูล่าง — "Liquid Glass" pill ลอย (iOS 26 · Apple Music / App Store) =====
// อ้างอิง: Apple "Adopting Liquid Glass" — วัสดุโปร่งแสงที่หักเห/สะท้อนเนื้อหาข้างหลัง,
// มี specular highlight ที่ขอบ, เงา adaptive, capsule ที่เลือก "ลอยเป็นกระจกบนกระจก" (ไม่ใช่แผ่นเทาทึบ).
// เนื้อ Liquid Glass ที่แท้จริง (จากรีเสิร์ช): (1) backdrop blur หนา 40–48 (2) "เพิ่มความอิ่มสี"
// ของเนื้อหาข้างหลัง (3) overlay tint จาง + ไล่เงาหักเหแสงแนวทแยง + specular ที่ขอบ.
// (1)+(2) ทำได้ด้วย ImageFilter.compose(outer: ColorFilter.matrix(saturate), inner: blur) — ไม่ต้องใช้ fragment shader
// (fragment shader / package liquid_glass_* = Impeller-only → พังบน web/windows ที่เวิร์กโฟลว์นี้ใช้ dev).
// AppShell ต้อง `extendBody: true` · หน้าเว้นล่าง = MediaQuery.of(context).padding.bottom · FAB ที่ navInset + 16
const double kNavBarHeight = 64; // ความสูงเนื้อหาใน pill
const double kNavBarMargin = 14; // ระยะขอบรอบ pill
const double kGlassBlur = 40; // "thick material" (nav) = 40–48 sigma
const double kGlassSaturation = 1.5; // เพิ่มความอิ่มสีเนื้อหาข้างหลัง (Liquid Glass "boost")

// -- พื้น pill: frost เย็นอ่อน โปร่งแสงพอให้ blur ทำงานเมื่อเนื้อหาไหลผ่านใต้ (บนพื้นขาวล้วน = "ghost glass" เลี่ยงไม่ได้) --
const kGlassFill = Color(0xEBEFF1F6); // α≈0.92 · over white ≈ #F0F2F6 (inactive grey 5.34:1)
const kGlassSolid = Color(0xFFF1F2F5); // a11y: Reduce Transparency → พื้นทึบ (ไม่มี blur)
const kGlassSheenTop = Color(0x3DFFFFFF); // ไล่เงาโค้งกระจก — สว่างที่ขอบบน (~24% ตามรีเสิร์ช)
const kGlassSheenBottom = Color(0x0AFFFFFF); // จางเกือบหมดที่ขอบล่าง
const kGlassRim = Color(0x141B2233); // เส้นขอบนอก pill (บาง เข้มนิด)
const kGlassSheen = Color(0x66FFFFFF); // เส้นขอบใน 40% ขาว 1px (ทั้ง light/dark ตามรีเสิร์ช)
const kGlassShadow = Color(0x24151B2E); // เงาใต้ pill (ทำให้ลอย)

// -- capsule แท็บที่เลือก = "กระจกวางบนกระจก": BackdropFilter ของตัวเอง + ไล่เงาหักเหแสงแนวทแยง + specular + เรืองฟ้า --
//    ไม่ย้อมพื้น capsule เป็นสี → คุม contrast ตัวอักษรได้ · สัญญาณ active = เรืองฟ้า + ไอคอน fill + weight
const kGlassCapTop = Color(0xF7FFFFFF); // α≈0.97 ขาวสว่าง — ครึ่งบน
const kGlassCapBottom = Color(0xCCEEF3FA); // α≈0.80 ฟ้าขาวจาง — ครึ่งล่าง (จำลองการหักเหแสง)
const kGlassCapSheen = Color(0x3AFFFFFF); // ไล่เงาหักเหแสงแนวทแยง (top-left ~23% ขาว → จาง)
const kGlassCapRim = Color(0x24FFFFFF); // specular ขอบบน 14% → จาง 2% (ไล่)
const kGlassCapBorder = Color(0x59FFFFFF); // ขอบ capsule ~35% ขาว 1px
const kGlassCapEdge = Color(0x14000000); // นิยามขอบล่าง (เส้นบาง)
const kGlassCapGlow = Color(0x261E96FC); // เรืองฟ้าจางรอบ capsule = สัญญาณ active

// -- ไอคอน+ป้าย --
const kNavActiveFg = Color(0xFF1565C0); // active — ฟ้าอ่านง่าย (บน capsule ≥ 5.0:1)
const kNavInactiveFg = Color(0xFF5B6472); // inactive — เทา iOS (บน frost ≥ 4.8:1)

// ===== ระยะห่าง 8pt grid + มุมโค้ง (Apple HIG · iOS 26 = โค้งขึ้น, ตัวเลขเป็น multiple ของ 4) =====
// ใช้ค่าจากสเกลนี้เสมอ — ห้าม magic number (13 / 17 / 22). concentric: inner radius = outer − padding
const double kSpace1 = 4;
const double kSpace2 = 8;
const double kSpace3 = 12;
const double kSpace4 = 16; // = content margin มาตรฐาน iOS + padding ภายในการ์ด (Apple `.padding()`)
const double kSpace5 = 20; // section inset / โล่งขึ้น
const double kSpace6 = 24;
const double kSpace8 = 32;
const double kRadiusChip = 10; // chip / control เล็ก
const double kRadiusCard = 18; // การ์ด
const double kRadiusSheet = 22; // ชีต / dialog ใหญ่

// ===== Motion — เลียนสปริง SwiftUI (.smooth / .snappy / .bouncy) =====
// Flutter implicit-anim รับ Curve ไม่ใช่ spring จริง → ใช้ curve ประมาณ + duration ด้านล่าง
// hero interaction (nav capsule / sheet) ที่อยากได้ฟิสิกส์จริง ใช้ AnimationController + SpringSimulation
const kDurQuick = Duration(milliseconds: 200); // micro: สี / opacity / press
const kDurBase = Duration(
  milliseconds: 340,
); // ทั่วไป: position / size / capsule
const kDurSheet = Duration(milliseconds: 440); // ชีต / หน้าใหญ่
const Curve kCurveSmooth = Curves
    .easeOutCubic; // .smooth — ไม่ overshoot (ดีฟอลต์ของ transition ทั่วไป)
const Curve kCurveSnappy = Cubic(
  0.22,
  1.0,
  0.30,
  1.03,
); // .snappy — overshoot จิ๊ดเดียว (เลือก/สลับสถานะ)
const Curve kCurveBouncy = Cubic(
  0.34,
  1.5,
  0.5,
  1.0,
); // .bouncy — เด้งชัด (เฉพาะ celebratory: ทำงานเสร็จ / streak)
const double kPressScale =
    0.97; // ปุ่ม / การ์ด: กด → ย่อ 0.97 + opacity ~0.92 แล้วสปริงกลับ

// เงามาตรฐานของการ์ดขาว — พื้นหน้าก็ขาว (1:1) → การ์ดทุกใบต้องมีเงานี้ (หรือเส้น kOutline) ไม่งั้นแยกไม่ออก
final List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 16,
    offset: const Offset(0, 6),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 3,
    offset: const Offset(0, 1),
  ),
];

// ให้ลาก "คลิกค้างแล้วปัด" ด้วยเมาส์ได้ (ดีฟอลต์ของ Flutter บนเว็บ/เดสก์ท็อป = ปัดได้เฉพาะทัชสกรีน)
// → PageView เปลี่ยนเดือน + scroll อื่น ๆ ตอบสนองเมาส์เหมือนกันทั้งแอป
// ตั้งเป็น MaterialApp.scrollBehavior เดียวทั้งแอป → ปรับที่นี่จุดเดียวมีผลทุกหน้า
class DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  // ไม่โชว์แถบ scrollbar เลยทุกหน้า (ผู้ใช้ขอ) — เลื่อนด้วยสัมผัส/ลากเมาส์ได้ปกติ แค่ไม่มีแถบเทาให้เห็น
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}