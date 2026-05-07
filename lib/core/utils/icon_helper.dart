import 'package:flutter/material.dart';

// Non-const map (Dart forbids .codePoint in const contexts) but all VALUES
// are const Icons.X references — the tree shaker resolves each one.
// No non-const IconData constructor is called anywhere, so --no-tree-shake-icons
// is not needed.
final Map<int, IconData> _kIconMap = {
  Icons.restaurant.codePoint: Icons.restaurant,
  Icons.local_grocery_store.codePoint: Icons.local_grocery_store,
  Icons.directions_bus.codePoint: Icons.directions_bus,
  Icons.shopping_bag.codePoint: Icons.shopping_bag,
  Icons.receipt_long.codePoint: Icons.receipt_long,
  Icons.movie.codePoint: Icons.movie,
  Icons.favorite.codePoint: Icons.favorite,
  Icons.flight.codePoint: Icons.flight,
  Icons.school.codePoint: Icons.school,
  Icons.payments.codePoint: Icons.payments,
  Icons.fitness_center.codePoint: Icons.fitness_center,
  Icons.pets.codePoint: Icons.pets,
  Icons.home.codePoint: Icons.home,
  Icons.car_rental.codePoint: Icons.car_rental,
  Icons.coffee.codePoint: Icons.coffee,
  Icons.cake.codePoint: Icons.cake,
  Icons.work.codePoint: Icons.work,
  Icons.devices.codePoint: Icons.devices,
  Icons.book.codePoint: Icons.book,
  Icons.savings.codePoint: Icons.savings,
  Icons.help_outline.codePoint: Icons.help_outline,
  Icons.category.codePoint: Icons.category,
  Icons.label.codePoint: Icons.label,
  Icons.receipt.codePoint: Icons.receipt,
  Icons.bar_chart.codePoint: Icons.bar_chart,
  Icons.show_chart.codePoint: Icons.show_chart,
  Icons.account_balance_wallet_outlined.codePoint: Icons.account_balance_wallet_outlined,
};

/// Returns a const [IconData] for [codePoint], or [Icons.help_outline] if unknown.
IconData iconForCodePoint(int codePoint) =>
    _kIconMap[codePoint] ?? Icons.help_outline;
