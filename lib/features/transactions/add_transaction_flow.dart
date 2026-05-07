import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/models/frequency.dart';
import '../../data/models/transaction_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/categories_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import '../receipts/camera_capture_page.dart';
import 'widgets/currency_input.dart';

class AddTransactionFlow extends ConsumerStatefulWidget {
  const AddTransactionFlow({this.editing, super.key});

  final TransactionModel? editing;

  static Future<bool?> show(
    BuildContext context, {
    TransactionModel? editing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTransactionFlow(editing: editing),
    );
  }

  @override
  ConsumerState<AddTransactionFlow> createState() =>
      _AddTransactionFlowState();
}

class _AddTransactionFlowState extends ConsumerState<AddTransactionFlow> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int _step = 0;
  double? _amount;
  String? _amountError;
  CategoryModel? _category;
  DateTime _date = DateTime.now();
  String? _receiptPath;
  bool _isIncome = false;
  bool _isRecurring = false;
  Frequency _frequency = Frequency.monthly;
  bool _saving = false;

  static const int _stepCount = 5;

  @override
  void initState() {
    super.initState();
    final tx = widget.editing;
    if (tx != null) {
      _amount = tx.amount;
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _date = tx.date;
      _notesCtrl.text = tx.notes ?? '';
      _receiptPath = tx.receiptPath;
      _isIncome = tx.isIncome;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _amount != null && _amount! > 0;
      case 1:
        return _category != null;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (!_canAdvance) {
      await Haptics.warning();
      return;
    }
    await Haptics.tap();
    if (_step == _stepCount - 1) {
      await _save();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    Haptics.tap();
    setState(() => _step--);
  }

  Future<void> _save() async {
    if (_amount == null || _category == null) return;
    setState(() => _saving = true);
    final txRepo = ref.read(transactionRepositoryProvider);
    final recurringRepo = ref.read(recurringRepositoryProvider);
    try {
      String? recurringRuleId;
      if (_isRecurring && widget.editing == null) {
        final rule = await recurringRepo.create(
          frequency: _frequency,
          startDate: _date,
          baseAmount: _amount!,
          categoryId: _category!.id,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          isIncome: _isIncome,
        );
        recurringRuleId = rule.id;
      }

      if (widget.editing != null) {
        final tx = widget.editing!.copyWith(
          amount: _amount,
          categoryId: _category!.id,
          date: _date,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          receiptPath: _receiptPath,
          isIncome: _isIncome,
        );
        await txRepo.update(tx);
      } else {
        await txRepo.create(
          amount: _amount!,
          categoryId: _category!.id,
          date: _date,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          receiptPath: _receiptPath,
          recurringRuleId: recurringRuleId,
          isIncome: _isIncome,
        );
      }
      await Haptics.success();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      await Haptics.error();
      if (mounted) {
        setState(() {
          _amountError = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + viewInsets),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: _step, total: _stepCount),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: Container(
                key: ValueKey(_step),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildStep(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _back,
                    child: Text(
                      _step == 0
                          ? AppLocalizations.of(context).cancel
                          : AppLocalizations.of(context).back,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _step == _stepCount - 1
                                ? AppLocalizations.of(context).save
                                : AppLocalizations.of(context).next,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _AmountStep(
          controller: _amountCtrl,
          isIncome: _isIncome,
          errorText: _amountError,
          onChanged: (v) => setState(() {
            _amount = v;
            _amountError = null;
          }),
          onIncomeToggle: (v) => setState(() {
            _isIncome = v;
            _category = null;
          }),
        );
      case 1:
        return _CategoryStep(
          isIncome: _isIncome,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        );
      case 2:
        return _DateStep(
          date: _date,
          onChanged: (d) => setState(() => _date = d),
        );
      case 3:
        return _ReceiptStep(
          path: _receiptPath,
          onCapture: () async {
            final path = await CameraCapturePage.show(context);
            if (path != null && mounted) {
              setState(() => _receiptPath = path);
            }
          },
          onClear: () => setState(() => _receiptPath = null),
        );
      case 4:
        return _NotesStep(
          notesController: _notesCtrl,
          isRecurring: _isRecurring,
          frequency: _frequency,
          onRecurringToggle: (v) => setState(() => _isRecurring = v),
          onFrequencyChanged: (f) => setState(() => _frequency = f),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.controller,
    required this.isIncome,
    required this.onChanged,
    required this.onIncomeToggle,
    this.errorText,
  });

  final TextEditingController controller;
  final bool isIncome;
  final ValueChanged<double?> onChanged;
  final ValueChanged<bool> onIncomeToggle;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.amount, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        CurrencyInput(
          controller: controller,
          onChanged: onChanged,
          errorText: errorText,
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: isIncome,
          onChanged: onIncomeToggle,
          title: Text(l.isIncome),
        ),
      ],
    );
  }
}

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep({
    required this.isIncome,
    required this.selected,
    required this.onSelected,
  });

  final bool isIncome;
  final CategoryModel? selected;
  final ValueChanged<CategoryModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories = isIncome
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.selectCategory, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final c = categories[i];
              final isSelected = selected?.id == c.id;
              return _CategoryTile(
                category: c,
                selected: isSelected,
                onTap: () => onSelected(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconForCodePoint(category.iconCodePoint),
              color: color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateStep extends ConsumerWidget {
  const _DateStep({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final localeTag = ref.watch(settingsProvider).locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.date, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(DateHelpers.formatDate(date, localeTag)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ),
                lastDate:
                    DateTime.now().add(const Duration(days: 365 * 5)),
                initialDate: date,
              );
              if (picked != null) onChanged(picked);
            },
          ),
        ),
      ],
    );
  }
}

class _ReceiptStep extends StatelessWidget {
  const _ReceiptStep({
    required this.path,
    required this.onCapture,
    required this.onClear,
  });

  final String? path;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.receipt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (path != null && File(path!).existsSync())
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, size: 64),
              ),
            ),
          )
        else
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Icon(Icons.receipt_long, size: 56)),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onCapture,
                icon: const Icon(Icons.camera_alt),
                label: Text(l.captureReceipt),
              ),
            ),
            if (path != null) ...[
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({
    required this.notesController,
    required this.isRecurring,
    required this.frequency,
    required this.onRecurringToggle,
    required this.onFrequencyChanged,
  });

  final TextEditingController notesController;
  final bool isRecurring;
  final Frequency frequency;
  final ValueChanged<bool> onRecurringToggle;
  final ValueChanged<Frequency> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.notes, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(hintText: l.notes),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: isRecurring,
          onChanged: onRecurringToggle,
          title: Text(l.recurring),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: isRecurring
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<Frequency>(
                    segments: [
                      ButtonSegment(
                        value: Frequency.daily,
                        label: Text(l.frequencyDaily),
                      ),
                      ButtonSegment(
                        value: Frequency.weekly,
                        label: Text(l.frequencyWeekly),
                      ),
                      ButtonSegment(
                        value: Frequency.monthly,
                        label: Text(l.frequencyMonthly),
                      ),
                    ],
                    selected: {frequency},
                    onSelectionChanged: (s) =>
                        onFrequencyChanged(s.first),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
