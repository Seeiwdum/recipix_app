import '../entities/recipe.dart';

/// How well the available ingredients cover one recipe.
final class RecipeMatch {
  RecipeMatch({
    required this.recipe,
    required Set<String> haveKeys,
    required Set<String> missingKeys,
    this.focusHits = 0,
  }) : haveKeys = Set.unmodifiable(haveKeys),
       missingKeys = Set.unmodifiable(missingKeys);

  final Recipe recipe;

  /// Required keys the user has.
  final Set<String> haveKeys;

  /// Required keys the user lacks.
  final Set<String> missingKeys;

  /// How many of the "focus" keys (e.g. the spun reels) the recipe uses.
  final int focusHits;

  /// Share of required ingredients available, 0.0 to 1.0.
  double get matchRatio {
    final total = haveKeys.length + missingKeys.length;
    return total == 0 ? 0 : haveKeys.length / total;
  }

  /// [matchRatio] as a whole-number percentage, rounded down so 99.6% is
  /// never shown as 100%.
  int get matchPercentage => (matchRatio * 100).floor();

  /// Everything required is on hand.
  bool get isJackpot => missingKeys.isEmpty && haveKeys.isNotEmpty;
}

/// Set-based recipe matching (ported from the Unity HashSet approach).
final class RecipeMatcher {
  const RecipeMatcher();

  RecipeMatch match(
    Recipe recipe,
    Set<String> availableKeys, {
    Set<String> focusKeys = const {},
  }) {
    final have = recipe.requiredKeys.intersection(availableKeys);
    final missing = recipe.requiredKeys.difference(availableKeys);
    final allKeys = {for (final i in recipe.ingredients) i.key};
    return RecipeMatch(
      recipe: recipe,
      haveKeys: have,
      missingKeys: missing,
      focusHits: allKeys.intersection(focusKeys).length,
    );
  }

  /// Ranks recipes by score (the match ratio, or the weighted score below),
  /// then match ratio, focus hits, fewest missing items, and name for a
  /// stable order.
  ///
  /// When [focusKeys] is non-empty, recipes that use none of them are
  /// dropped, so a spin always yields a dish built around what was rolled.
  ///
  /// With [weighFocus] (the slot machine), the first key is
  /// `matchRatio x share of focus keys used`: a dish that uses all three
  /// reels at 80% beats a complete dish that uses only one of them.
  List<RecipeMatch> rank(
    Iterable<Recipe> recipes,
    Set<String> availableKeys, {
    Set<String> focusKeys = const {},
    bool weighFocus = false,
  }) {
    final matches = [
      for (final r in recipes) match(r, availableKeys, focusKeys: focusKeys),
    ].where((m) => focusKeys.isEmpty || m.focusHits > 0).toList();

    double score(RecipeMatch m) => weighFocus && focusKeys.isNotEmpty
        ? m.matchRatio * m.focusHits / focusKeys.length
        : m.matchRatio;

    matches.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      final byRatio = b.matchRatio.compareTo(a.matchRatio);
      if (byRatio != 0) return byRatio;
      final byFocus = b.focusHits.compareTo(a.focusHits);
      if (byFocus != 0) return byFocus;
      final byMissing = a.missingKeys.length.compareTo(b.missingKeys.length);
      if (byMissing != 0) return byMissing;
      return a.recipe.name.compareTo(b.recipe.name);
    });
    return matches;
  }
}
