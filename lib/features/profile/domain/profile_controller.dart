import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../shared/persistence/app_store.dart';
import '../../../shared/persistence/codecs.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';

/// The user, as told at first launch (ADR-017). On this device only.
final class UserProfile {
  UserProfile({
    this.name = '',
    Set<String> favoriteRecipeIds = const {},
    this.monthlyFoodSpend,
    this.completedOn,
  }) : favoriteRecipeIds = Set.unmodifiable(favoriteRecipeIds);

  final String name;
  final Set<String> favoriteRecipeIds;

  /// What they usually spend on food in a month (they may skip it).
  final Money? monthlyFoodSpend;

  /// Null until the first-launch questions are done.
  final LocalDate? completedOn;

  bool get isComplete => completedOn != null;
}

/// The first-launch answers, before they are applied.
final class OnboardingAnswers {
  OnboardingAnswers({
    required this.name,
    this.favoriteRecipeIds = const {},
    this.monthlyFoodSpend,
    required this.moneyLeft,
    this.paydayDayOfMonth,
  });

  final String name;
  final Set<String> favoriteRecipeIds;
  final Money? monthlyFoodSpend;

  /// Money left for food from now until payday.
  final Money moneyLeft;

  /// Null = not fixed (the budget runs to the end of the month).
  final int? paydayDayOfMonth;
}

final profileProvider = NotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final store = ref.watch(appStoreProvider);
    if (store != null) {
      listenSelf(
        (_, next) => store.saveProfile(
          SavedProfile(
            name: next.name,
            favoriteRecipeIds: next.favoriteRecipeIds.toList(),
            monthlyFoodSpend: next.monthlyFoodSpend,
            completedOn: next.completedOn,
          ),
        ),
      );
    }
    final saved = ref.watch(savedDataProvider).profile;
    if (saved == null) return UserProfile();
    return UserProfile(
      name: saved.name,
      favoriteRecipeIds: saved.favoriteRecipeIds.toSet(),
      monthlyFoodSpend: saved.monthlyFoodSpend,
      completedOn: saved.completedOn,
    );
  }

  /// Meal price guessed from a month's food spend: three meals a day for
  /// 30 days, rounded to 5 baht, kept within everyday prices.
  static Money mealPriceFrom(Money monthly) {
    final perMeal = monthly.satang / 100 / 90;
    final rounded = (perMeal / 5).round() * 5;
    return Money.baht(rounded.clamp(20, 300));
  }

  /// Applies the answers (ADR-017):
  /// - a brand-new install starts with an empty fridge and no spending
  ///   (the sample data was only a demo); an install that already has the
  ///   user's own data keeps it;
  /// - the period budget is set so that what is left equals [moneyLeft];
  /// - payday and (when given) the meal price follow the answers.
  void complete(OnboardingAnswers a) {
    if (ref.read(savedDataProvider).isFreshInstall) {
      ref.read(fridgeProvider.notifier).startEmpty();
      ref.read(budgetProvider.notifier).startFresh();
    }
    final budget = ref.read(budgetProvider.notifier);
    budget.setPayday(a.paydayDayOfMonth);
    final spentThisPeriod =
        ref.read(budgetProvider).periodBudget -
        ref.read(ledgerProvider).remaining;
    budget.setPeriodBudget(a.moneyLeft + spentThisPeriod);
    if (a.monthlyFoodSpend case final monthly? when !monthly.isZero) {
      budget.setMealOutPrice(mealPriceFrom(monthly));
    }
    state = UserProfile(
      name: a.name.trim(),
      favoriteRecipeIds: a.favoriteRecipeIds,
      monthlyFoodSpend: a.monthlyFoodSpend,
      completedOn: ref.read(todayProvider),
    );
  }
}
