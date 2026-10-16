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

  // Fridge tab
  static String fridgeCapacity(int used, int total) =>
      'ใช้ไป $used จาก $total ช่อง';
  static const filterAll = 'ทั้งหมด';
  static const filterUseSoon = 'ต้องใช้ก่อน';
  static const filterProduce = 'ผักผลไม้';
  static const filterProtein = 'เนื้อ ไข่ นม';
  static const filterUnknown = 'ไม่รู้ชนิด';
  static const basketTitle = 'ตะกร้า';
  static const basketHint = 'ลากขึ้นไปวางบนชั้น';
  static const basketEmpty = 'จัดของเข้าตู้ครบแล้ว';
  static String basketMore(int n) => '+$n';
  static const drawerLabel = 'ลิ้นชักผัก';
  static const compartmentNames = {
    'freezer': 'ช่องแช่แข็ง',
    'shelf1': 'ชั้นบน',
    'shelf2': 'ชั้นกลาง',
    'shelf3': 'ชั้นล่าง',
    'crisper': 'ลิ้นชักผัก',
    'door': 'ชั้นประตู',
  };
  static const inBasket = 'อยู่ในตะกร้า';
  static const today = 'วันนี้';
  static const expired = 'หมดแล้ว';
  static String daysShort(int days) => '$days วัน';

  // Item sheet
  static const sheetExpiry = 'หมดอายุ';
  static const sheetEnergy = 'พลังงาน';
  static const sheetPlace = 'ที่เก็บ';
  static const actionUse = 'ใช้แล้ว';
  static const actionDiscard = 'ทิ้ง';
  static const actionToBasket = 'ย้ายไปตะกร้า';
  static const actionAutoPlace = 'จัดเข้าตู้ให้';
  static const fridgeFull = 'ตู้เต็ม ย้ายของออกก่อน';
  static String expiryLine(String date, int daysLeft) => switch (daysLeft) {
    < 0 => '$date · เลยมา ${-daysLeft} วัน',
    0 => '$date · วันนี้วันสุดท้าย',
    _ => '$date · อีก $daysLeft วัน',
  };
  static String kcal(int value) => '$value kcal';
  static String kcalEstimate(int value) => 'ประมาณ $value kcal (ยังไม่รู้ชนิด)';
  static const monthsShort = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  static const units = {
    'piece': 'ชิ้น',
    'gram': 'ก.',
    'kilogram': 'กก.',
    'milliliter': 'มล.',
    'liter': 'ล.',
  };

  // Toasts
  static String toastUsed(String name) => 'ใช้$nameแล้ว';
  static String toastDiscarded(String name) => 'ทิ้ง$nameแล้ว';
  static const undo = 'เลิกทำ';

  // Sample data for previews (replaced by assets/data in Phase 2)
  static const sampleGarlic = 'กระเทียม';
}
