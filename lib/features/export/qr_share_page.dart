import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_providers.dart';
import 'json_exporter.dart';

class QrSharePage extends ConsumerWidget {
  const QrSharePage({super.key});

  static const int _qrCapacity = 2900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final db = ref.watch(hiveDatabaseProvider);
    final snapshot = JsonSnapshot(db).toJsonMap();
    final raw = utf8.encode(jsonEncode(snapshot));
    final compressed = GZipEncoder().encode(raw);
    final encoded = base64Url.encode(compressed!);
    final fits = encoded.length <= _qrCapacity;

    return Scaffold(
      appBar: AppBar(title: Text(l.exportQr)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              fits
                  ? '${(encoded.length / 1024).toStringAsFixed(1)} KB compressed payload'
                  : 'Payload too large for a single QR (${(encoded.length / 1024).toStringAsFixed(1)} KB).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (fits)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        data: encoded,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Use ${l.exportJson} or ${l.exportCsv} instead.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
