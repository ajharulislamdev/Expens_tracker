import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    this.onTap,
    this.remainingBalance,
  });

  final TransactionModel tx;
  final VoidCallback? onTap;
  final double? remainingBalance;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? AppColors.income : AppColors.expense;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(AppConstants.iconFor(tx.category), color: color),
      ),
      title: Text(tx.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Obx(
        () => Text(
          remainingBalance == null
              ? '${tx.category} • ${DateFormat('d MMM y, h:mm a').format(tx.date)}'
              : '${tx.category} • ${DateFormat('d MMM y, h:mm a').format(tx.date)}\n'
                  'Balance after transaction: ${CurrencyFormatter.format(remainingBalance!)}',
        ),
      ),
      trailing: Obx(
        () => Text(
          '${tx.isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
