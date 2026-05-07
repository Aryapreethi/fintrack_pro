import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return l ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Map<String, String> get _strings => _all[locale.languageCode] ?? _all['en']!;

  String _t(String key) => _strings[key] ?? _all['en']![key] ?? key;

  String get appTitle => _t('appTitle');
  String get tabDashboard => _t('tabDashboard');
  String get tabTransactions => _t('tabTransactions');
  String get tabBudget => _t('tabBudget');
  String get tabCategories => _t('tabCategories');
  String get tabSettings => _t('tabSettings');
  String get addTransaction => _t('addTransaction');
  String get amount => _t('amount');
  String get category => _t('category');
  String get date => _t('date');
  String get notes => _t('notes');
  String get receipt => _t('receipt');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get next => _t('next');
  String get back => _t('back');
  String get done => _t('done');
  String get today => _t('today');
  String get yesterday => _t('yesterday');
  String get totalSpent => _t('totalSpent');
  String get dailyAverage => _t('dailyAverage');
  String get budget => _t('budget');
  String get noTransactions => _t('noTransactions');
  String get noTransactionsHint => _t('noTransactionsHint');
  String get biometricPrompt => _t('biometricPrompt');
  String get exportJson => _t('exportJson');
  String get exportCsv => _t('exportCsv');
  String get exportQr => _t('exportQr');
  String get restoreFromFile => _t('restoreFromFile');
  String get settingsTheme => _t('settingsTheme');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsBiometric => _t('settingsBiometric');
  String get settingsDynamicColor => _t('settingsDynamicColor');
  String get settingsReducedMotion => _t('settingsReducedMotion');
  String get themeSystem => _t('themeSystem');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get languageEnglish => _t('languageEnglish');
  String get languageHindi => _t('languageHindi');
  String get recurring => _t('recurring');
  String get frequencyDaily => _t('frequencyDaily');
  String get frequencyWeekly => _t('frequencyWeekly');
  String get frequencyMonthly => _t('frequencyMonthly');
  String get isIncome => _t('isIncome');
  String get captureReceipt => _t('captureReceipt');
  String get selectCategory => _t('selectCategory');
  String get monthlyBudget => _t('monthlyBudget');
  String get remaining => _t('remaining');
  String get overBudget => _t('overBudget');
  String get pullToRefresh => _t('pullToRefresh');
  String get exitAppTitle => _t('exitAppTitle');
  String get exitAppMessage => _t('exitAppMessage');
  String get exit => _t('exit');

  String transactionsThisMonth(int count) {
    if (locale.languageCode == 'hi') {
      if (count == 0) return 'कोई लेन-देन नहीं';
      if (count == 1) return '1 लेन-देन';
      return '$count लेन-देन';
    }
    if (count == 0) return 'No transactions';
    if (count == 1) return '1 transaction';
    return '$count transactions';
  }

  static const Map<String, Map<String, String>> _all = {
    'en': {
      'appTitle': 'FinTrack Pro',
      'tabDashboard': 'Dashboard',
      'tabTransactions': 'Transactions',
      'tabBudget': 'Budget',
      'tabCategories': 'Categories',
      'tabSettings': 'Settings',
      'addTransaction': 'Add Transaction',
      'amount': 'Amount',
      'category': 'Category',
      'date': 'Date',
      'notes': 'Notes',
      'receipt': 'Receipt',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'next': 'Next',
      'back': 'Back',
      'done': 'Done',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'totalSpent': 'Total Spent',
      'dailyAverage': 'Daily Average',
      'budget': 'Budget',
      'noTransactions': 'No transactions yet',
      'noTransactionsHint': 'Tap + to add your first transaction.',
      'biometricPrompt': 'Authenticate to open FinTrack Pro',
      'exportJson': 'Export as JSON',
      'exportCsv': 'Export as CSV',
      'exportQr': 'Share as QR',
      'restoreFromFile': 'Restore from file',
      'settingsTheme': 'Theme',
      'settingsLanguage': 'Language',
      'settingsBiometric': 'Require biometric on launch',
      'settingsDynamicColor': 'Use system dynamic color',
      'settingsReducedMotion': 'Reduce motion',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'languageEnglish': 'English',
      'languageHindi': 'हिन्दी',
      'recurring': 'Recurring',
      'frequencyDaily': 'Daily',
      'frequencyWeekly': 'Weekly',
      'frequencyMonthly': 'Monthly',
      'isIncome': 'This is income',
      'captureReceipt': 'Capture Receipt',
      'selectCategory': 'Select Category',
      'monthlyBudget': 'Monthly Budget',
      'remaining': 'Remaining',
      'overBudget': 'Over budget',
      'pullToRefresh': 'Pull to refresh',
      'exitAppTitle': 'Exit app?',
      'exitAppMessage': 'Are you sure you want to exit FinTrack Pro?',
      'exit': 'Exit',
    },
    'hi': {
      'appTitle': 'फिनट्रैक प्रो',
      'tabDashboard': 'डैशबोर्ड',
      'tabTransactions': 'लेन-देन',
      'tabBudget': 'बजट',
      'tabCategories': 'श्रेणियाँ',
      'tabSettings': 'सेटिंग्स',
      'addTransaction': 'लेन-देन जोड़ें',
      'amount': 'राशि',
      'category': 'श्रेणी',
      'date': 'तारीख़',
      'notes': 'नोट्स',
      'receipt': 'रसीद',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'मिटाएँ',
      'edit': 'संपादित करें',
      'next': 'आगे',
      'back': 'पीछे',
      'done': 'पूर्ण',
      'today': 'आज',
      'yesterday': 'कल',
      'totalSpent': 'कुल ख़र्च',
      'dailyAverage': 'दैनिक औसत',
      'budget': 'बजट',
      'noTransactions': 'अभी तक कोई लेन-देन नहीं',
      'noTransactionsHint': 'अपना पहला लेन-देन जोड़ने के लिए + दबाएँ।',
      'biometricPrompt': 'फिनट्रैक प्रो खोलने के लिए प्रमाणीकरण करें',
      'exportJson': 'JSON के रूप में निर्यात',
      'exportCsv': 'CSV के रूप में निर्यात',
      'exportQr': 'QR के रूप में साझा करें',
      'restoreFromFile': 'फ़ाइल से पुनर्स्थापित करें',
      'settingsTheme': 'थीम',
      'settingsLanguage': 'भाषा',
      'settingsBiometric': 'प्रारंभ पर बायोमेट्रिक आवश्यक',
      'settingsDynamicColor': 'सिस्टम डायनेमिक रंग उपयोग करें',
      'settingsReducedMotion': 'एनिमेशन कम करें',
      'themeSystem': 'सिस्टम',
      'themeLight': 'हल्का',
      'themeDark': 'गहरा',
      'languageEnglish': 'English',
      'languageHindi': 'हिन्दी',
      'recurring': 'आवर्ती',
      'frequencyDaily': 'दैनिक',
      'frequencyWeekly': 'साप्ताहिक',
      'frequencyMonthly': 'मासिक',
      'isIncome': 'यह आय है',
      'captureReceipt': 'रसीद कैप्चर करें',
      'selectCategory': 'श्रेणी चुनें',
      'monthlyBudget': 'मासिक बजट',
      'remaining': 'शेष',
      'overBudget': 'बजट से अधिक',
      'pullToRefresh': 'रीफ़्रेश करने के लिए खींचें',
      'exitAppTitle': 'ऐप से बाहर निकलें?',
      'exitAppMessage': 'क्या आप वाक़ई फिनट्रैक प्रो से बाहर निकलना चाहते हैं?',
      'exit': 'बाहर निकलें',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
