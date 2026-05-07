import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/settings_providers.dart';

/// Big-amount currency input with real-time formatting and validation states.
class CurrencyInput extends ConsumerStatefulWidget {
  const CurrencyInput({
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.autofocus = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<double?> onChanged;
  final String? errorText;
  final bool autofocus;

  @override
  ConsumerState<CurrencyInput> createState() => _CurrencyInputState();
}

class _CurrencyInputState extends ConsumerState<CurrencyInput> {
  bool _focused = false;
  late final FocusNode _focus = FocusNode()
    ..addListener(() => setState(() => _focused = _focus.hasFocus));

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = ref.watch(currencyFormatterProvider);
    final symbol = _symbolFor(fmt.currencyCode);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasError
                  ? scheme.error
                  : (_focused
                      ? scheme.primary
                      : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  symbol,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                    _SingleDecimalFormatter(fmt.localeTag),
                  ],
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                    filled: false,
                    isCollapsed: true,
                  ),
                  onChanged: (raw) {
                    widget.onChanged(fmt.parse(raw));
                  },
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: hasError
              ? Padding(
                  key: ValueKey(widget.errorText),
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(color: scheme.error),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  static String _symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
      case 'CNY':
        return '¥';
      default:
        return code;
    }
  }
}

class _SingleDecimalFormatter extends TextInputFormatter {
  _SingleDecimalFormatter(this.localeTag);

  final String localeTag;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final separator =
        NumberFormat.decimalPattern(localeTag).symbols.DECIMAL_SEP;
    final text = newValue.text;
    final separatorIdx = text.indexOf(separator);
    if (separatorIdx == -1) return newValue;
    if (text.indexOf(separator, separatorIdx + 1) != -1) return oldValue;
    final decimals = text.substring(separatorIdx + 1);
    if (decimals.length > 2) return oldValue;
    return newValue;
  }
}
