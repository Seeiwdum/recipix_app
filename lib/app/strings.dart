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

  // Home tab (daily report)
  static const weekdays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  static const survivalLead = 'อยู่ได้อีก';
  static const daysUnit = 'วัน';
  static const bahtUnit = 'บาท';
  static String survivalBasis(String kcal, String need) =>
      'จากของที่มี $kcal kcal · ใช้วันละ $need kcal';
  static String survivalEstimate(String days) =>
      'ถ้านับของที่ยังไม่รู้ชนิดด้วย อาจได้ถึง $days วัน';
  static String coverage(String days, int payday) =>
      'ของในตู้พอ $days จาก $payday วันถึงเงินเข้า';
  static const allowanceLabel = 'งบวันนี้';
  static const paydayLabel = 'เงินเข้าใน';
  static String deficit(String baht) => 'ขาดอีก $baht บาทถึงวันเงินเข้า';
  static const budgetCovered = 'งบพอถึงวันเงินเข้า';
  static const useFirstTitle = 'ต้องใช้ก่อน';
  static const useFirstHint = 'ปัดขวา ใช้แล้ว · ปัดซ้าย ทิ้ง';
  static const useFirstEmpty = 'ไม่มีของที่ต้องรีบใช้';
  static String daysLeftLong(int days) => switch (days) {
    < 0 => 'หมดอายุแล้ว',
    0 => 'ควรใช้วันนี้',
    _ => 'เหลือ $days วัน',
  };
  static const menuTitle = 'เมนูที่ใช้ของใกล้หมด';
  static const menuFull = 'ครบทุกอย่าง';
  static String menuMissing(String names) => 'ขาด $names';
  static String matchPercent(int p) => 'เข้ากัน $p%';
  static String minutes(int m) => '$m นาที';

  // Spending log
  static String spentToday(String spent, String left) =>
      'ใช้ไป $spent · เหลือ $left บาท';
  static String overToday(String over) => 'เกินงบวันนี้ $over บาท';
  static const logSpending = 'บันทึกค่ากิน';
  static const spendTitle = 'บันทึกค่ากิน';
  static const spendAmountHint = '0';
  static const spendCategories = {
    'eatOut': 'กินข้างนอก',
    'groceries': 'ซื้อของเข้าบ้าน',
    'other': 'อื่นๆ',
  };
  static const spendSave = 'บันทึก';
  static const spendTodayTitle = 'วันนี้';
  static const spendNoneToday = 'วันนี้ยังไม่ได้บันทึก';
  static String spendSaved(String baht) => 'บันทึก $baht บาทแล้ว';
  static const spendRemove = 'ลบรายการ';
  static const eatOutCountsAsMeal = 'นับเป็น 1 มื้อในแผน';

  // Meal plan
  static const nextMealTitle = 'มื้อถัดไป';
  static const seePlan = 'ดูแผน';
  static const planTitle = 'แผนกินถึงวันเงินเข้า';
  static const back = 'กลับ';
  static String planHomeSummary(int home, int total) =>
      'ทำเองได้อีก $home มื้อ จาก $total มื้อถึงเงินเข้า';
  static const planHomeLead = 'ทำเองจากของในตู้';
  static const mealsUnit = 'มื้อ';
  static String planOfTotal(int total) => 'จาก $total มื้อถึงวันเงินเข้า';
  static String planEatOut(int meals, String baht) =>
      'ซื้อกิน $meals มื้อ ประมาณ $baht บาท';
  static String planBudgetLeft(String baht) => 'งบเหลือ $baht บาท';
  static String planShortfall(String baht) => 'ตามแผนนี้ ขาด $baht บาท';
  static const planCovered = 'ตามแผนนี้ งบพอ';
  static String planWillSpoil(String names) => 'จะเสียก่อนได้ใช้: $names';
  static const mealNames = ['มื้อเช้า', 'มื้อกลางวัน', 'มื้อเย็น'];
  static String mealName(int slot) =>
      slot < mealNames.length ? mealNames[slot] : 'มื้อที่ ${slot + 1}';
  static const eatOutMeal = 'ซื้อกิน';
  static const tomorrow = 'พรุ่งนี้';
  static String usesLine(String names) => 'ใช้ $names';
  static const cookUses = 'จะใช้ของในตู้';
  static const cookDone = 'ทำแล้ว';
  static const cookMissing = 'ของในตู้ไม่พอแล้ว';
  static String toastCooked(String name) => 'ทำ$nameแล้ว';

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
