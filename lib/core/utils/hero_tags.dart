/// Centralized Hero tag namespace to avoid collisions across the app.
class HeroTags {
  const HeroTags._();

  // Dashboard ↔ Transactions
  static const String summaryTotal = 'hero-summary-total';
  static const String summaryDailyAvg = 'hero-summary-daily-avg';
  static const String summaryBudget = 'hero-summary-budget';

  // Dashboard ↔ Add transaction sheet
  static const String fabAdd = 'hero-fab-add';

  // Budget tab ↔ Edit budget
  static const String budgetRing = 'hero-budget-ring';

  // Donut center label ↔ Transactions header
  static const String donutCenter = 'hero-donut-center';

  // Tab-level shells (used by tab navigator transitions)
  static String tabShell(int index) => 'hero-tab-$index';

  // Dynamic tags
  static String category(String id) => 'hero-category-$id';
  static String receipt(String txnId) => 'hero-receipt-$txnId';
  static String transactionRow(String txnId) => 'hero-tx-$txnId';
}
