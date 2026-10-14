import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import 'theme.dart';

/// ข้อมูลเพื่อน (ค่าจำลอง) — ใช้ร่วมกันระหว่างหน้า "แบ่งปันเวลาอ่าน" และ "โปรไฟล์เพื่อน"
/// เวลาจริงควรมาจาก backend: ถ้าเพื่อนปิด [showTime]/[showStatus] ฝั่งเซิร์ฟเวอร์ต้อง "ไม่ส่งค่า"
/// มาให้เลย (ไม่ใช่แค่ซ่อนใน UI) ไม่งั้นคนที่ดักดู response ก็ยังเห็น
@immutable
class Friend {
  const Friend({
    required this.code,
    required this.initial,
    required this.name,
    required this.avatarBg,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalHours,
    required this.streak,
    required this.challengeMinutes,
    this.weekBars = const [0.2, 0.4, 0.7, 0.3, 0.5, 0.4, 0.8],
    this.isReadingNow = false,
    this.readingNowMinutes = 0,
    this.showTime = true,
    this.showStatus = true,
  });

  final String code; // รหัสเพื่อน เช่น ARN-1001
  final String initial;
  final String name;
  final Color avatarBg;
  final int todayMinutes;
  final int weekMinutes;
  final int totalHours;
  final int streak; // วันติดต่อกัน (0 = ไม่แสดง)
  final int challengeMinutes; // เวลาที่ช่วยสะสมให้ชาเลนจ์สัปดาห์นี้
  final List<double> weekBars; // 7 วัน สัดส่วน 0–1
  final bool isReadingNow;
  final int readingNowMinutes;

  /// เพื่อนยอมให้เห็นเวลาอ่านหรือไม่ (ปิด = เรามองไม่เห็นเวลา/กราฟ/อันดับของเขา)
  final bool showTime;

  /// เพื่อนยอมให้เห็นสถานะออนไลน์ ("กำลังอ่านอยู่") หรือไม่
  final bool showStatus;

  int minutesFor(int tab) => tab == 0 ? todayMinutes : weekMinutes;

  /// เห็นว่า "กำลังอ่านอยู่" ได้ก็ต่อเมื่อเพื่อนเปิดสถานะ
  bool get visibleReading => showStatus && isReadingNow;
}

const kMockFriends = <Friend>[
  Friend(
    code: 'ARN-1001',
    initial: 'ม',
    name: 'มายด์',
    avatarBg: kBrandFillSoft,
    todayMinutes: 92,
    weekMinutes: 640,
    totalHours: 92,
    streak: 12,
    challengeMinutes: 200,
    isReadingNow: true,
    readingNowMinutes: 12,
  ),
  Friend(
    code: 'ARN-1002',
    initial: 'ป',
    name: 'ปอนด์',
    avatarBg: kYellowFill,
    todayMinutes: 68,
    weekMinutes: 410,
    totalHours: 41,
    streak: 1,
    challengeMinutes: 150,
    weekBars: [0.5, 0.3, 0.6, 0.4, 0.7, 0.2, 0.5],
    isReadingNow: true, // กำลังอ่านจริง แต่ปิดสถานะ → เราไม่เห็น
    readingNowMinutes: 30,
    showStatus: false,
  ),
  Friend(
    code: 'ARN-1003',
    initial: 'ฟ',
    name: 'ฟ้าใส',
    avatarBg: kPinkFill,
    todayMinutes: 30,
    weekMinutes: 255,
    totalHours: 18,
    streak: 1,
    challengeMinutes: 120,
    showTime: false, // ปิดการแสดงเวลาอ่าน
  ),
  Friend(
    code: 'ARN-1004',
    initial: 'เจ',
    name: 'เจโล',
    avatarBg: kMintFill,
    todayMinutes: 22,
    weekMinutes: 190,
    totalHours: 25,
    streak: 0,
    challengeMinutes: 90,
    weekBars: [0.3, 0.2, 0.4, 0.5, 0.1, 0.3, 0.2],
  ),
  Friend(
    code: 'ARN-1005',
    initial: 'ย',
    name: 'ยีน',
    avatarBg: kLavenderFill,
    todayMinutes: 15,
    weekMinutes: 120,
    totalHours: 9,
    streak: 0,
    challengeMinutes: 80,
    showTime: false, // ปิดทั้งเวลาและสถานะ
    showStatus: false,
  ),
  Friend(
    code: 'ARN-1006',
    initial: 'บ',
    name: 'บัว',
    avatarBg: kPeachFill,
    todayMinutes: 8,
    weekMinutes: 75,
    totalHours: 5,
    streak: 0,
    challengeMinutes: 56,
    weekBars: [0.1, 0.2, 0.1, 0.3, 0.1, 0.0, 0.2],
  ),
];

/// รหัสเพื่อนของฉัน (ค่าจำลอง)
const kMyFriendCode = 'ARN-4821';

/// เวลาที่ฉันช่วยสะสมให้ชาเลนจ์สัปดาห์นี้ (นาที · ค่าจำลอง)
const kMyChallengeMinutes = 120;

// ---------------------------------------------------------------------------
// ความเป็นส่วนตัวของ "ฉัน" — เปิด/ปิดได้อิสระ · ค่าจำลองเป็น global notifier
// (ตอนต่อ backend ให้ย้ายไปไว้ใน state management / repository และ sync ขึ้นเซิร์ฟเวอร์)
// ---------------------------------------------------------------------------

/// เพื่อนเห็น "เวลาอ่าน" ของฉันหรือไม่
final ValueNotifier<bool> myShowTime = ValueNotifier<bool>(true);

/// เพื่อนเห็น "สถานะออนไลน์ / กำลังอ่านอยู่" ของฉันหรือไม่
final ValueNotifier<bool> myShowStatus = ValueNotifier<bool>(true);

/// "2 ชม. 15 น." / "45 นาที"
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m นาที';
  if (m == 0) return '$h ชม.';
  return '$h ชม. $m น.';
}