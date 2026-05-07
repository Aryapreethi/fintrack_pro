import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_providers.dart';

class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({this.editing, super.key});

  final CategoryModel? editing;

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    CategoryModel? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CategoryForm(editing: editing),
    );
  }

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  late final TextEditingController _nameCtrl;
  late int _iconCodePoint;
  late int _colorValue;
  late bool _isIncome;

  static final List<IconData> _iconChoices = [
    Icons.restaurant,
    Icons.local_grocery_store,
    Icons.directions_bus,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.movie,
    Icons.favorite,
    Icons.flight,
    Icons.school,
    Icons.payments,
    Icons.fitness_center,
    Icons.pets,
    Icons.home,
    Icons.car_rental,
    Icons.coffee,
    Icons.cake,
    Icons.work,
    Icons.devices,
    Icons.book,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _iconCodePoint = e?.iconCodePoint ?? Icons.label.codePoint;
    _colorValue = e?.colorValue ?? AppColors.donutPalette.first.toARGB32();
    _isIncome = e?.isIncome ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (widget.editing != null) {
      final updated = widget.editing!.copyWith(
        name: name,
        iconCodePoint: _iconCodePoint,
        colorValue: _colorValue,
        isIncome: _isIncome,
      );
      await repo.update(updated);
    } else {
      await repo.create(
        name: name,
        iconCodePoint: _iconCodePoint,
        colorValue: _colorValue,
        isIncome: _isIncome,
      );
    }
    await Haptics.success();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final color = Color(_colorValue);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  iconForCodePoint(_iconCodePoint),
                  size: 40,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l.category),
              autofocus: widget.editing == null,
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isIncome,
              onChanged: (v) => setState(() => _isIncome = v),
              title: Text(l.isIncome),
            ),
            const SizedBox(height: 8),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in AppColors.donutPalette)
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = c.toARGB32()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorValue == c.toARGB32()
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final ic in _iconChoices)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _iconCodePoint = ic.codePoint),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _iconCodePoint == ic.codePoint
                            ? color.withValues(alpha: 0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _iconCodePoint == ic.codePoint
                              ? color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(ic, color: color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
