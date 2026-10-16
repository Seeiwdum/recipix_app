import 'package:flutter/material.dart';

import '../../app/theme/recipix_tokens.dart';

/// Standard tab page: safe area, page title, scrollable body.
class RecipixPage extends StatelessWidget {
  const RecipixPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space3,
              RecipixTokens.space4,
              RecipixTokens.space3,
              RecipixTokens.space3,
            ),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Text(title, style: t.pageTitle),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: RecipixTokens.space3,
            ),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}

/// Quiet note shown on tabs that are not built yet.
class ComingSoonNote extends StatelessWidget {
  const ComingSoonNote({super.key, required this.status, required this.text});

  final String status;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Plain text, no card: an unfinished screen should say so honestly,
    // not dress it up (critique: ธนากร).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status, style: t.title),
        const SizedBox(height: RecipixTokens.space1),
        Text(text, style: t.bodyMuted),
      ],
    );
  }
}
