import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/budget_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import '../dashboard/widgets/budget_progress.dart';
import '../transactions/widgets/currency_input.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  final _amountCtrl = TextEditingController();
  double? _amount;
  String? _error;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amount == null || _amount! <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(budgetRepositoryProvider);
      final currency = ref.read(settingsProvider).currencyCode;
      await repo.setActive(monthlyLimit: _amount!, currency: currency);
      await Haptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
      await Haptics.error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(budgetProgressProvider);
    final budget = ref.watch(activeBudgetProvider).maybeWhen(
          data: (v) => v,
          orElse: () => null,
        );
    final fmt = ref.watch(currencyFormatterProvider);

    if (!_initialized && budget != null) {
      _amountCtrl.text = budget.monthlyLimit.toStringAsFixed(2);
      _amount = budget.monthlyLimit;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.tabBudget)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (progress != null) ...[
            Center(
              child: BudgetRing(
                fraction: progress.fraction,
                label: l.remaining,
                value: fmt.formatCompact(progress.remaining),
                isOver: progress.isOver,
                size: 220,
                reducedMotion: ref.watch(reducedMotionProvider),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                progress.isOver
                    ? l.overBudget
                    : '${fmt.format(progress.spent)} / ${fmt.format(progress.limit)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            l.monthlyBudget,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          CurrencyInput(
            controller: _amountCtrl,
            onChanged: (v) => setState(() {
              _amount = v;
              _error = null;
            }),
            errorText: _error,
            autofocus: false,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
    );
  }
}
