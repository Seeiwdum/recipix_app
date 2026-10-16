import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../shared/persistence/app_store.dart';
import '../../../shared/persistence/codecs.dart';

/// Pay-period budget, editable prices and the spending log.
final class BudgetState {
  BudgetState({
    required this.periodBudget,
    required List<SpendingEntry> entries,
    required List<Money> quickAmounts,
    this.paydayDayOfMonth,
    this.prices = const PriceSettings(),
    this.lastAdded,
  }) : entries = List.unmodifiable(entries),
       quickAmounts = List.unmodifiable(quickAmounts);

  /// Money for food for the whole pay period.
  final Money periodBudget;
  final int? paydayDayOfMonth;
  final PriceSettings prices;
  final List<SpendingEntry> entries;

  /// One-tap amounts in the spending sheet. Settings data, not UI
  /// constants (the old demo hard-coded prices on screen).
  final List<Money> quickAmounts;

  /// Last entry added, for the undo toast.
  final SpendingEntry? lastAdded;

  BudgetState copyWith({
    List<SpendingEntry>? entries,
    SpendingEntry? lastAdded,
    bool clearLastAdded = false,
    Money? periodBudget,
    int? paydayDayOfMonth,
    bool clearPayday = false,
    PriceSettings? prices,
  }) => BudgetState(
    periodBudget: periodBudget ?? this.periodBudget,
    paydayDayOfMonth: clearPayday
        ? null
        : (paydayDayOfMonth ?? this.paydayDayOfMonth),
    prices: prices ?? this.prices,
    quickAmounts: quickAmounts,
    entries: entries ?? this.entries,
    lastAdded: clearLastAdded ? null : (lastAdded ?? this.lastAdded),
  );
}

final budgetProvider = NotifierProvider<BudgetController, BudgetState>(
  BudgetController.new,
);

class BudgetController extends Notifier<BudgetState> {
  /// Restores the saved budget and spending log, or on first launch seeds a
  /// sample: one eat-out entry per past day of the period and a period
  /// budget that leaves 1,600 baht today (ADR-009).
  @override
  BudgetState build() {
    final store = ref.watch(appStoreProvider);
    if (store != null) {
      listenSelf((_, next) => store.saveBudget(_toSaved(next)));
    }
    final saved = ref.watch(savedDataProvider).budget;
    if (saved != null) {
      return BudgetState(
        periodBudget: saved.periodBudget,
        paydayDayOfMonth: saved.paydayDayOfMonth,
        prices: saved.prices,
        quickAmounts: saved.quickAmounts,
        entries: saved.entries,
      );
    }

    final today = ref.watch(todayProvider);
    final start = const BudgetLedger().periodStart(null, today);
    final entries = <SpendingEntry>[
      for (var d = start; d.isBefore(today); d = d.addDays(1))
        SpendingEntry(
          id: 'sample-$d',
          date: d,
          amount: Money.baht(d.day.isEven ? 180 : 200),
        ),
    ];
    final spent = entries.fold(Money.zero, (s, e) => s + e.amount);
    final initial = BudgetState(
      periodBudget: spent + Money.baht(1600),
      entries: entries,
      quickAmounts: [Money.baht(40), Money.baht(60), Money.baht(100)],
    );
    store?.saveBudget(_toSaved(initial));
    return initial;
  }

  static SavedBudget _toSaved(BudgetState s) => SavedBudget(
    periodBudget: s.periodBudget,
    paydayDayOfMonth: s.paydayDayOfMonth,
    prices: s.prices,
    quickAmounts: s.quickAmounts,
    entries: s.entries,
  );

  var _seq = 0;

  SpendingEntry add(Money amount, SpendCategory category) {
    final entry = SpendingEntry(
      id: 'spend-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      date: ref.read(todayProvider),
      amount: amount,
      category: category,
    );
    state = state.copyWith(
      entries: [...state.entries, entry],
      lastAdded: entry,
    );
    return entry;
  }

  /// Limits keep the steppers sane; not business rules.
  static final maxPeriodBudget = Money.baht(200000);
  static final maxMealPrice = Money.baht(2000);

  void setPeriodBudget(Money value) => state = state.copyWith(
    periodBudget: Money.min(maxPeriodBudget, Money.max(Money.zero, value)),
  );

  /// Null = budget runs to the end of the month.
  void setPayday(int? day) => state = day == null
      ? state.copyWith(clearPayday: true)
      : state.copyWith(paydayDayOfMonth: day.clamp(1, 31));

  void setMealOutPrice(Money value) => state = state.copyWith(
    prices: state.prices.copyWith(
      mealOutPrice: Money.min(maxMealPrice, Money.max(Money.baht(1), value)),
    ),
  );

  /// Drops the sample spending log, for a new user's first setup
  /// (ADR-017). Settings stay.
  void startFresh() =>
      state = state.copyWith(entries: const [], clearLastAdded: true);

  void remove(String id) => state = state.copyWith(
    entries: state.entries.where((e) => e.id != id).toList(),
    clearLastAdded: state.lastAdded?.id == id,
  );
}

final ledgerProvider = Provider<LedgerSummary>((ref) {
  final b = ref.watch(budgetProvider);
  return const BudgetLedger().summarize(
    periodBudget: b.periodBudget,
    paydayDayOfMonth: b.paydayDayOfMonth,
    entries: b.entries,
    today: ref.watch(todayProvider),
  );
});

/// The profile the survival rules run on: what is left right now.
final budgetProfileProvider = Provider<UserBudgetProfile>((ref) {
  final b = ref.watch(budgetProvider);
  return UserBudgetProfile(
    foodBudget: ref.watch(ledgerProvider).remaining,
    paydayDayOfMonth: b.paydayDayOfMonth,
    prices: b.prices,
  );
});

/// Spending logged today, newest first.
final todaySpendingProvider = Provider<List<SpendingEntry>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(budgetProvider)
      .entries
      .where((e) => e.date == today)
      .toList()
      .reversed
      .toList();
});
