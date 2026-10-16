import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/value_stepper.dart';
import '../domain/profile_controller.dart';

/// First launch (ADR-017): name, favourite dishes, money. Three short
/// steps, one primary button each. The router sends a new user here and
/// on to the home tab once done.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _steps = 3;

  int _step = 0;
  final _name = TextEditingController();
  final _monthly = TextEditingController();
  final _left = TextEditingController();
  final _favorites = <String>{};
  int? _payday;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _monthly, _left]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _monthly.dispose();
    _left.dispose();
    super.dispose();
  }

  static Money? _baht(String text) {
    final v = int.tryParse(text.replaceAll(',', '').trim());
    return v == null ? null : Money.baht(v);
  }

  bool get _canGoOn => switch (_step) {
    0 => _name.text.trim().isNotEmpty,
    1 => true,
    _ => _baht(_left.text) != null,
  };

  void _next() {
    if (!_canGoOn) return;
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    HapticFeedback.lightImpact();
    ref
        .read(profileProvider.notifier)
        .complete(
          OnboardingAnswers(
            name: _name.text,
            favoriteRecipeIds: _favorites,
            monthlyFoodSpend: _baht(_monthly.text),
            moneyLeft: _baht(_left.text)!,
            paydayDayOfMonth: _payday,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RecipixTokens.space3,
            RecipixTokens.space1,
            RecipixTokens.space3,
            RecipixTokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: RecipixTokens.tapTarget,
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        key: const ValueKey('onboard-back'),
                        tooltip: S.back,
                        onPressed: () => setState(() => _step--),
                        icon: RecipixIcon(
                          RecipixIcons.chevronLeft,
                          color: t.ink,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      S.onboardStep(_step + 1, _steps),
                      style: t.label.copyWith(
                        color: t.ink2,
                        fontFeatures: RecipixTokens.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: RecipixTokens.medium,
                    child: KeyedSubtree(
                      key: ValueKey('onboard-step-$_step'),
                      child: switch (_step) {
                        0 => _NameStep(controller: _name, onDone: _next),
                        1 => _FoodStep(
                          selected: _favorites,
                          onToggle: (id) => setState(
                            () => _favorites.contains(id)
                                ? _favorites.remove(id)
                                : _favorites.add(id),
                          ),
                        ),
                        _ => _MoneyStep(
                          monthly: _monthly,
                          left: _left,
                          payday: _payday,
                          onPayday: (d) => setState(() => _payday = d),
                        ),
                      },
                    ),
                  ),
                ),
              ),
              if (_step == _steps - 1) ...[
                Text(
                  S.onboardPrivacy,
                  textAlign: TextAlign.center,
                  style: t.caption,
                ),
                const SizedBox(height: RecipixTokens.space2),
              ],
              SizedBox(
                height: RecipixTokens.tapTarget,
                child: FilledButton(
                  key: const ValueKey('onboard-next'),
                  onPressed: _canGoOn ? _next : null,
                  child: Text(
                    _step == _steps - 1 ? S.onboardStart : S.onboardNext,
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

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onDone});

  final TextEditingController controller;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: RecipixTokens.space4),
        Semantics(
          header: true,
          child: Text(S.onboardWelcome, style: t.pageTitle),
        ),
        const SizedBox(height: RecipixTokens.space1),
        Text(S.onboardLead, style: t.bodyMuted),
        const SizedBox(height: RecipixTokens.space5),
        Text(S.onboardNameLabel, style: t.label),
        _Field(
          fieldKey: const ValueKey('onboard-name'),
          controller: controller,
          hint: S.onboardNameHint,
          autofocus: true,
          onSubmitted: onDone,
          style: t.title,
        ),
      ],
    );
  }
}

class _FoodStep extends ConsumerWidget {
  const _FoodStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final recipes = ref.watch(recipeBookProvider).recipes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: RecipixTokens.space4),
        Semantics(
          header: true,
          child: Text(S.onboardFoodTitle, style: t.pageTitle),
        ),
        const SizedBox(height: RecipixTokens.space1),
        Text(S.onboardFoodHint, style: t.bodyMuted),
        const SizedBox(height: RecipixTokens.space4),
        Wrap(
          spacing: RecipixTokens.space2,
          runSpacing: RecipixTokens.space2,
          children: [
            for (final r in recipes)
              Pressable(
                key: ValueKey('fav-${r.id}'),
                selected: selected.contains(r.id),
                semanticLabel: r.name,
                onTap: () => onToggle(r.id),
                child: AnimatedContainer(
                  duration: RecipixTokens.fast,
                  constraints: const BoxConstraints(
                    minHeight: RecipixTokens.tapTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: RecipixTokens.space3,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected.contains(r.id) ? t.surface : null,
                    border: Border.all(
                      color: selected.contains(r.id) ? t.accent : t.line,
                    ),
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
                  ),
                  child: Text(
                    r.name,
                    style: t.body.copyWith(
                      color: selected.contains(r.id) ? t.accent : t.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MoneyStep extends StatelessWidget {
  const _MoneyStep({
    required this.monthly,
    required this.left,
    required this.payday,
    required this.onPayday,
  });

  final TextEditingController monthly;
  final TextEditingController left;
  final int? payday;
  final ValueChanged<int?> onPayday;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: RecipixTokens.space4),
        Semantics(
          header: true,
          child: Text(S.onboardMoneyTitle, style: t.pageTitle),
        ),
        const SizedBox(height: RecipixTokens.space4),
        Text(S.onboardLeftLabel, style: t.label),
        Text(S.onboardLeftHint, style: t.caption),
        _Field(
          fieldKey: const ValueKey('onboard-left'),
          controller: left,
          hint: S.amountHint,
          number: true,
          unit: S.bahtUnit,
          style: t.display,
        ),
        const SizedBox(height: RecipixTokens.space4),
        Text(S.onboardMonthlyLabel, style: t.label),
        Text(S.onboardMonthlyHint, style: t.caption),
        _Field(
          fieldKey: const ValueKey('onboard-monthly'),
          controller: monthly,
          hint: S.amountHint,
          number: true,
          unit: S.bahtUnit,
          style: t.title,
        ),
        const SizedBox(height: RecipixTokens.space4),
        ValueStepper(
          key: const ValueKey('onboard-payday'),
          label: S.paydaySetting,
          value: payday == null ? S.paydayEndOfMonth : S.paydayDay(payday!),
          decreaseLabel: S.decrease(S.paydaySetting),
          increaseLabel: S.increase(S.paydaySetting),
          canDecrease: payday != null,
          canIncrease: payday != 31,
          // 0 = end of month, as on the dashboard.
          onStep: (n) {
            final next = ((payday ?? 0) + n).clamp(0, 31);
            onPayday(next == 0 ? null : next);
          },
        ),
      ],
    );
  }
}

/// An underlined text field in the app's paper style.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.style,
    this.number = false,
    this.unit,
    this.autofocus = false,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final TextStyle style;
  final bool number;
  final String? unit;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: TextField(
                key: fieldKey,
                controller: controller,
                autofocus: autofocus,
                keyboardType: number ? TextInputType.number : null,
                inputFormatters: number
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                textInputAction: TextInputAction.next,
                style: style,
                cursorColor: t.accent,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: style.copyWith(color: t.line),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: RecipixTokens.space1,
                  ),
                ),
                onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
              ),
            ),
            if (unit != null)
              Text(unit!, style: t.title.copyWith(color: t.ink2)),
          ],
        ),
        Divider(height: 1, color: t.line),
      ],
    );
  }
}
