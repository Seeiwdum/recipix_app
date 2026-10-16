/// All Thai user-facing text. Voice rules: skill `recipix-thai-copy`.
///
/// Kept as constants while the app is Thai-only; moving to gen-l10n later
/// only changes this file.
abstract final class S {
  static const appName = 'Recipix';

  // Tabs
  static const tabHome = 'หน้าหลัก';
  static const tabFridge = 'ตู้เย็น';
  static const tabScan = 'สแกน';
  static const tabRandom = 'สุ่มเมนู';
  static const tabDashboard = 'แดชบอร์ด';

  // Page headers
  static const homeTitle = 'วันนี้';
  static const fridgeTitle = 'ตู้เย็น';
  static const scanTitle = 'สแกนของเข้าตู้';
  static const randomTitle = 'สุ่มเมนู';
  static const dashboardTitle = 'แดชบอร์ด';

  // Placeholders until each tab is built (Phase 2)
  static const homeComingSoon =
      'ใบรายงานประจำวัน: วันที่อยู่ได้ งบวันนี้ และของที่ต้องใช้ก่อน';
  static const fridgeComingSoon =
      'หน้าตัดตู้เย็น ลากของจากตะกร้าไปวางบนชั้นได้';
  static const scanComingSoon = 'กล้องสำหรับวัตถุดิบ บาร์โค้ด และใบเสร็จ';
  static const randomComingSoon = 'วงล้อ 3 แกน หมุนหาเมนูจากของที่มี';
  static const dashboardComingSoon = 'งบอาหาร เหรียญรางวัล และเมนูที่กินบ่อย';
  static const underConstruction = 'กำลังทำ';

  // Badges (ids from recipix_core BadgeIds)
  static const badgeNames = {
    'clear_expiring': 'เคลียร์ของใกล้หมดอายุ',
    'budget_saver': 'ประหยัดงบสำเร็จ',
    'home_cook': 'ทำกินเองบ่อย',
    'zero_waste_week': 'ไม่ทิ้งของ 7 วัน',
    'first_scan': 'สแกนครั้งแรก',
  };

  // Ingredients
  static const mysteryItem = 'ยังไม่รู้ชนิด';

  // Sample data for previews (replaced by assets/data in Phase 2)
  static const sampleGarlic = 'กระเทียม';
}
