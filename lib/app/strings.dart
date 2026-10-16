/// All Thai user-facing text. Voice rules: skill `recipix-thai-copy`.
///
/// Kept as constants while the app is Thai-only; moving to gen-l10n later
/// only changes this file.
abstract final class S {
  static const appName = 'Recipix';

  // First launch (ADR-017)
  static String onboardStep(int n, int of) => '$n/$of';
  static const onboardWelcome = 'ยินดีต้อนรับสู่ Recipix';
  static const onboardLead =
      'ช่วยให้ค่ากินอยู่รอดถึงวันเงินเดือนออก ตอบ 3 ข้อแล้วเริ่มได้เลย';
  static const onboardNameLabel = 'เรียกคุณว่าอะไรดี';
  static const onboardNameHint = 'ชื่อเล่น';
  static const onboardFoodTitle = 'ปกติชอบกินอะไร';
  static const onboardFoodHint =
      'เลือกได้หลายเมนู เมนูที่เลือกจะขึ้นในเมนูแนะนำก่อน';
  static const onboardMoneyTitle = 'เรื่องเงินค่ากิน';
  static const onboardMonthlyLabel = 'ปกติใช้ค่ากินเดือนละเท่าไหร่';
  static const onboardMonthlyHint =
      'ไม่ต้องเป๊ะ แอปใช้เดาราคาอาหารต่อมื้อ เว้นว่างได้';
  static const onboardLeftLabel = 'ตอนนี้เหลือเงินไว้กินเท่าไหร่';
  static const onboardLeftHint = 'นับถึงวันเงินเดือนออกครั้งหน้า';
  static const onboardPrivacy = 'ข้อมูลทั้งหมดอยู่ในเครื่องนี้เท่านั้น';
  static const onboardNext = 'ต่อไป';
  static const onboardStart = 'เริ่มใช้ Recipix';
  static const amountHint = '0';
  static String greeting(String name) => 'สวัสดี $name';

  // Tabs
  static const tabHome = 'หน้าหลัก';
  static const tabFridge = 'ตู้เย็น';
  static const tabScan = 'สแกน';
  static const tabRandom = 'สุ่มเมนู';
  static const tabDashboard = 'สมุดค่ากิน';

  // Page headers
  static const homeTitle = 'วันนี้';
  static const fridgeTitle = 'ตู้เย็น';
  static const scanTitle = 'สแกนของเข้าตู้';
  static const randomTitle = 'สุ่มเมนู';
  static const dashboardTitle = 'สมุดค่ากิน';

  static const underConstruction = 'กำลังทำ';

  // Barcode scan (ADR-014)
  static const scanHint = 'เล็งบาร์โค้ดบนห่อให้อยู่ในกรอบ';
  static const scanLooking = 'กำลังหาชื่อสินค้า';
  static const scanNoName = 'พบบาร์โค้ด แต่ไม่มีชื่อสินค้า';
  static const scanNotFound = 'ไม่พบสินค้านี้ในฐานข้อมูล';
  static const scanOffline = 'ค้นชื่อสินค้าไม่ได้ตอนนี้';
  static const scanPickHint = 'เลือกว่าเป็นของอะไร ครั้งหน้าแอปจะจำได้';
  static const scanKnown = 'เคยสแกนแล้ว';
  static String scanAddKnown(String name) => 'เพิ่ม$nameลงตะกร้า';
  static const scanPickOther = 'ไม่ใช่ เลือกใหม่';
  static String scanAdded(String name) =>
      'เพิ่ม$nameลงตะกร้าแล้ว จัดเข้าชั้นได้ที่แท็บตู้เย็น';
  static String scanBarcode(String code) => 'บาร์โค้ด $code';
  static const scanNoBarcode = 'ไม่มีบาร์โค้ด เพิ่มของเอง';
  static const scanCameraDenied = 'แอปยังไม่ได้รับสิทธิ์ใช้กล้อง';
  static const scanCameraDeniedHint =
      'เปิดสิทธิ์กล้องให้ Recipix ในการตั้งค่าเครื่อง หรือเพิ่มของเองไปก่อน';
  static const scanCameraUnavailable = 'เครื่องนี้เปิดกล้องไม่ได้';
  static const scanCameraUnavailableHint = 'เพิ่มของเองได้จากปุ่มด้านล่าง';

  // Photo mode (ADR-016)
  static const scanModeBarcode = 'บาร์โค้ด';
  static const scanModePhoto = 'ถ่ายของ';
  static const photoHint = 'ถ่ายของที่ซื้อมา แอปจะตีกรอบให้ทีละชิ้น';
  static const photoFinding = 'กำลังหาของในภาพ';
  static const photoTapBox = 'แตะกรอบเพื่อบอกว่าเป็นอะไร';
  static String photoAdded(int n) => 'เพิ่มจากภาพนี้แล้ว $n ชิ้น';
  static const photoNone = 'ไม่เจอของในภาพ ลองถ่ายใกล้ขึ้น หรือเพิ่มของเอง';
  static const photoFailed =
      'เครื่องนี้หาของในภาพไม่ได้ ใช้โหมดบาร์โค้ดหรือเพิ่มของเองได้';
  static const photoRetake = 'ถ่ายใหม่';
  static const shutter = 'ถ่ายภาพ';
  static String photoBox(int n) => 'กรอบที่ $n';
  static const photoPickTitle = 'ชิ้นนี้คืออะไร';
  static const addByHand = 'เพิ่มของเอง';

  // Badges (ids from recipix_core BadgeIds)
  static const badgeNames = {
    // Short enough for one line on the stamp (the longer name broke
    // "หมดอายุ" in two).
    'clear_expiring': 'เคลียร์ของใกล้หมด',
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
  static const kcalUnit = 'kcal';
  static const fridgeEmptyHeadline = 'ยังนับไม่ได้ ตู้ยังว่าง';
  static const fridgeEmptyHint =
      'มีของในตู้เมื่อไหร่ จะนับให้ว่าทำกินได้กี่มื้อ';
  static String survivalBasis(String kcal, String need) =>
      'จากของที่มี $kcal kcal · ใช้วันละ $need kcal';
  static String survivalEstimate(String days) =>
      'ถ้านับของที่ยังไม่รู้ชนิดด้วย อาจได้ถึง $days วัน';
  static String coverage(String days, int payday) =>
      'ของในตู้พอ $days จาก $payday วันถึงเงินเข้า';
  static const paydayRow = 'เงินเข้าอีก';
  static const fridgeEnergyRow = 'พลังงานในตู้';
  static const shortfallEatOut = 'ยอดขาดถ้าซื้อกินทุกมื้อ';
  static const shortfallPlan = 'ยอดขาดถ้าทำเองตามแผน';
  static const enough = 'พอ';
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
  static const menuTitle = 'เมนูแนะนำ';
  static const menuHint = 'แตะดูวัตถุดิบและวิธีทำ';
  static const suggestFromFridge = 'จากของในตู้';
  static const suggestEasy = 'ทำง่าย';
  static const suggestFavorite = 'เมนูโปรด';

  // Recipe page (ADR-015)
  static const difficultyNames = {
    'easy': 'ง่าย',
    'medium': 'ปานกลาง',
    'hard': 'ยาก',
  };
  static String difficulty(String name) => 'ระดับ${difficultyNames[name]}';
  static const recipeIngredients = 'วัตถุดิบ';
  static const recipeSteps = 'วิธีทำ';
  static const recipeBadges = 'ทำเมนูนี้แล้วได้อะไร';
  static const recipeHave = 'มีแล้ว';
  static const recipeMissing = 'ขาด';
  static const recipeOptional = 'ไม่ใส่ก็ได้';
  static String recipeNeed(int n) => 'ขาดอีก $n อย่าง ทำได้เมื่อมีครบ';
  static const recipeNoSteps = 'ยังไม่มีวิธีทำของเมนูนี้';
  static const recipeNotFound = 'ไม่พบเมนูนี้';
  static String badgeGain(int n, int current, int target) =>
      '+$n · ${current + n > target ? target : current + n}/$target';
  static String badgeGainDone(int n) => '+$n · ได้แล้ว';
  static String badgeUnlocksNow(int n) => '+$n · ได้เหรียญนี้';
  static String stepNumber(int n) => '$n.';
  static const menuFull = 'ครบทุกอย่าง';
  static String menuMissing(String names) => 'ขาด $names';
  static String matchPercent(int p) => 'เข้ากัน $p%';
  static String matchPlain(int have, int total, int percent) =>
      'มีของ $have จาก $total · $percent%';
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
  static const planHomeLead = 'ทำกินเองจากของในตู้ได้อีก';
  static const mealsUnit = 'มื้อ';
  static String planOfTotal(int total) => 'จาก $total มื้อถึงวันเงินเข้า';
  static String planEatOut(int meals, String baht) =>
      'ซื้อกิน $meals มื้อ ประมาณ $baht บาท';
  static String planEatOutRow(int meals) => 'ซื้อกิน $meals มื้อ ประมาณ';
  static const planBudgetRow = 'งบที่เหลือ';
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

  // Dashboard
  static const budgetSection = 'งบอาหาร';
  static const periodBudgetLabel = 'งบรอบนี้';
  static String budgetUsed(String spent, String left) =>
      'ใช้ไปแล้ว $spent บาท · เหลือ $left บาท';
  static String budgetOverspent(String over) => 'ใช้เกินงบรอบนี้ $over บาท';
  static const remainingLabel = 'เหลือรอบนี้';
  static const overspentLabel = 'ใช้เกินงบรอบนี้';
  static String spentOfBudget(String spent, String budget) =>
      'ใช้ไป $spent จากงบ $budget บาท';
  static const settingsSection = 'ตั้งค่า';
  static const paydaySetting = 'วันเงินเข้า';
  static const paydayEndOfMonth = 'ใช้ถึงสิ้นเดือน';
  static String paydayDay(int day) => 'ทุกวันที่ $day';
  static const mealPriceSetting = 'ซื้อกินมื้อละ';
  static String decrease(String what) => 'ลด$what';
  static String increase(String what) => 'เพิ่ม$what';
  static const timelineTitle = 'รอบนี้';
  static const markWithin = 'อยู่ในงบ';
  static const markOver = 'เกินงบ';
  static const markNoRecord = 'ไม่ได้บันทึก';
  static const buysTitle = 'เงินที่เหลือซื้ออะไรได้';
  static String buysMeals(String price) => 'ซื้อกินมื้อละ $price บาท';
  static String buysDays(int meals) => 'ซื้อกินวันละ $meals มื้อ';
  static const buysAllowance = 'งบต่อวันถึงเงินเข้า';
  static String countMeals(int n) => '$n มื้อ';
  static String countDays(String n) => '$n วัน';
  static const badgesTitle = 'เหรียญ';
  static String badgeProgress(int c, int t) => '$c/$t';
  static String badgeUnlockedOn(String date) => 'ได้เมื่อ $date';
  static const badgeLocked = 'ยังไม่ได้';
  static const badgeRules = {
    'clear_expiring': 'ใช้ของที่เหลือ 0-2 วันให้ทันก่อนเสีย ครบ 5 ชิ้น',
    'budget_saver': 'ใช้เงินไม่เกินงบของวันนั้น 7 วันติดกัน',
    'home_cook': 'ทำกินเองจากของในตู้ 10 มื้อ',
    'zero_waste_week': 'ไม่ทิ้งของเลย 7 วันติดกัน',
    'first_scan': 'สแกนของเข้าตู้ครั้งแรก',
  };
  static const repeatsTitle = 'เมนูที่ทำบ่อย';
  static const repeatsEmpty = 'ยังไม่ได้ทำกินจากแอป ลองทำจากแผนกินดู';
  static String times(int n) => '$n ครั้ง';

  // Random menu tab
  static const modeCook = 'ทำเอง';
  static const modeEatOut = 'สั่งข้างนอก';
  static const spin = 'หมุน';
  static const spinHintCook = 'สุ่มวัตถุดิบ 3 อย่างจากตู้ แล้วหาเมนูที่ใช้ได้';
  static const spinHintEatOut = 'สุ่มเมนูที่ราคาไม่เกินงบที่เหลือวันนี้';
  static const lockHint = 'แตะแกนเพื่อล็อกวัตถุดิบไว้';
  static const preferExpiring = 'เน้นของใกล้หมดอายุ';
  static const locked = 'ล็อกแล้ว';
  static String reelLabel(int i, String name) => 'แกน ${i + 1}: $name';
  static const emptyReel = 'ยังไม่ได้หมุน';
  static const reelSpinning = 'กำลังหมุน';
  static const noMatch = 'ยังไม่มีเมนูที่ใช้ของชุดนี้ ลองหมุนใหม่หรือปลดล็อก';
  static const randomFridgeEmpty = 'ตู้ยังว่าง ยังไม่มีวัตถุดิบให้หมุน';
  static const tryEatOut = 'สุ่มเมนูสั่งข้างนอกแทน';
  static const fullNow = 'ทำได้ครบเลย';
  static const haveTitle = 'ของที่มี';
  static const missingTitle = 'ของที่ขาด';
  static const cookThis = 'ทำเมนูนี้';
  static const otherMatches = 'เมนูอื่นที่ใช้ของชุดนี้';
  static String priceBaht(String p) => '$p บาท';
  static String leftAfter(String baht) => 'เหลืองบวันนี้ $baht บาทหลังมื้อนี้';
  static String overAfter(String baht) => 'เกินงบวันนี้ $baht บาท';
  static const priceRow = 'ราคา';
  static const leftAfterRow = 'เหลืองบวันนี้หลังมื้อนี้';
  static const overTodayRow = 'เกินงบวันนี้';
  static const nothingFits =
      'ไม่มีเมนูในงบที่เหลือวันนี้ นี่คือเมนูที่ถูกที่สุด';
  static String eatThis(String baht) => 'กินมื้อนี้ · บันทึก $baht บาท';

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
  static const basketFridgeEmpty = 'ตู้ยังว่าง กดเพิ่มของที่ซื้อมา';

  // Add items by hand (ADR-013).
  static const addItem = 'เพิ่มของ';
  static const addItemTitle = 'เพิ่มของเข้าตะกร้า';
  static const addItemHint = 'แตะของที่ซื้อมา วันหมดอายุนับจากวันนี้ตามชนิด';
  static String keepsFor(int days) => 'เก็บได้ $days วัน';
  static String addedLine(String name, int count) =>
      'เพิ่ม$nameแล้ว · รอบนี้ $count ชิ้น';
  static const removeAdded = 'เอาออก';
  static const doneAdding = 'เสร็จ';
  static String addSemantics(String name) => 'เพิ่ม$name';
  static const goAddItems = 'ไปเพิ่มของในตู้เย็น';
  static const dropTooWide = 'ของชิ้นนี้กว้าง 2 ช่อง ใส่ชั้นประตูไม่ได้';
  static const dropTaken = 'ช่องนี้มีของอยู่แล้ว';
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
