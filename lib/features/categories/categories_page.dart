import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/hero_tags.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_providers.dart';
import 'category_form.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabCategories),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                CategoryForm.show(context, ref: ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
          itemCount: cats.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, i) {
            final c = cats[i];
            final color = Color(c.colorValue);
            return Dismissible(
              key: ValueKey(c.id),
              direction: c.isSystem
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.delete),
              ),
              confirmDismiss: (_) async {
                if (c.isSystem) return false;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Delete ${c.name}?'),
                    content: const Text(
                      'Existing transactions will be reassigned to "Uncategorized".',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.delete),
                      ),
                    ],
                  ),
                );
                return ok == true;
              },
              onDismissed: (_) async {
                await ref.read(categoryRepositoryProvider).delete(c.id);
                await Haptics.warning();
              },
              child: ListTile(
                onTap: () => CategoryForm.show(context, ref: ref, editing: c),
                leading: Hero(
                  tag: HeroTags.category(c.id),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconForCodePoint(c.iconCodePoint),
                      color: color,
                    ),
                  ),
                ),
                title: Text(c.name),
                subtitle: Text(c.isIncome ? 'Income' : 'Expense'),
                trailing: c.isSystem
                    ? Icon(
                        Icons.lock_outline,
                        size: 16,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
    );
  }
}
