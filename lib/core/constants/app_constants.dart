import 'package:flutter/material.dart';
import '../../data/models/transaction_type.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Expense Tracker';
  static const String exportFolder = 'ExpenseTracker';

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Rent',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Gift',
    'Investment',
    'Other',
  ];

  static List<String> categoriesFor(TransactionType type) =>
      type == TransactionType.expense ? expenseCategories : incomeCategories;

  static const Map<String, IconData> _icons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Health': Icons.medical_services,
    'Education': Icons.school,
    'Entertainment': Icons.movie,
    'Rent': Icons.home,
    'Salary': Icons.payments,
    'Business': Icons.storefront,
    'Gift': Icons.card_giftcard,
    'Investment': Icons.trending_up,
    'Other': Icons.category,
  };

  static IconData iconFor(String category) =>
      _icons[category] ?? Icons.category;
}
