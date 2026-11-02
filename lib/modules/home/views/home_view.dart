import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/summary_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../transactions/widgets/transaction_tile.dart';
import '../controllers/home_controller.dart';
import '../widgets/summary_tile.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 0,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Obx(() {
              final account = authController.account.value;
              final photoBytes = account?.photoBytes;
              return Semantics(
                button: true,
                label: account == null ? 'Profile' : 'Profile: ${account.name}',
                child: IconButton(
                  tooltip: 'Open account settings',
                  onPressed: () => controller.tabIndex.value = 3,
                  padding: EdgeInsets.zero,
                  icon: CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    foregroundImage:
                        photoBytes == null ? null : MemoryImage(photoBytes),
                    child: photoBytes != null
                        ? null
                        : Text(
                            _initialFor(account),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ),
        title: Obx(() => Center(
              child: PopupMenuButton<Object>(
                tooltip: 'Select month or reporting period',
                onSelected: (value) {
                  if (value is DateTime) {
                    controller.selectedMonth.value = value;
                    controller.period.value = SummaryPeriod.monthly;
                  } else if (value is SummaryPeriod) {
                    controller.period.value = value;
                  }
                },
                itemBuilder: (_) {
                  final now = DateTime.now();
                  final months = List<DateTime>.generate(
                    12,
                    (index) => DateTime(now.year, now.month - index, 1),
                  );
                  return [
                    const PopupMenuItem<Object>(
                      enabled: false,
                      child: Text('Choose a month'),
                    ),
                    ...months.map(
                      (month) => PopupMenuItem<Object>(
                        value: month,
                        child: Text(DateFormat('MMMM yyyy').format(month)),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<Object>(
                      value: SummaryPeriod.weekly,
                      child: Text('This week'),
                    ),
                    const PopupMenuItem<Object>(
                      value: SummaryPeriod.daily,
                      child: Text('Today'),
                    ),
                  ];
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.periodLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 19),
                    ],
                  ),
                ),
              ),
            )),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => SnackbarHelper.info('You are all caught up.'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        final overall = controller.overall;
        final summary = controller.summary;
        final recent = controller.recent;
        final recentBalances = <String, double>{};
        var runningBalance = 0.0;
        for (final transaction in controller.allTransactions.reversed) {
          runningBalance += transaction.signedAmount;
          recentBalances[transaction.id] = runningBalance;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            _BalanceCard(
              amount: overall.balance,
              transactionCount: overall.count,
              weeklyChange: controller.weeklyBalanceChange,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SummaryTile(
                  label: 'Income',
                  amount: summary.income,
                  color: AppColors.income,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryTile(
                  label: 'Expenses',
                  amount: summary.expense,
                  color: AppColors.expense,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ]),
            const SizedBox(height: 18),
            _InsightBanner(
              onTap: () => SnackbarHelper.info(
                'Personalized insights are coming soon.',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Recent transactions',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => controller.tabIndex.value = 4,
                  child: const Text('See all'),
                ),
              ],
            ),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nothing yet. Tap "Add" to record your first one.'),
              )
            else
              ...recent.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Card(
                    child: TransactionTile(
                      tx: transaction,
                      remainingBalance: recentBalances[transaction.id],
                      onTap: () => Get.toNamed(
                        AppRoutes.form,
                        arguments: transaction,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _initialFor(AccountModel? account) {
    final name = account?.name.trim() ?? '';
    return name.isEmpty ? 'A' : name[0].toUpperCase();
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.amount,
    required this.transactionCount,
    required this.weeklyChange,
  });

  final double amount;
  final int transactionCount;
  final double weeklyChange;

  @override
  Widget build(BuildContext context) {
    final changeColor =
        weeklyChange >= 0 ? const Color(0xFFB8F2D8) : const Color(0xFFFFC5CC);
    final changePrefix = weeklyChange > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 21, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34388F), Color(0xFF6468E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                weeklyChange >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 17,
                color: changeColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Obx(
                  () => Text(
                    '$changePrefix${CurrencyFormatter.format(weeklyChange)} vs last week',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Text(
                '$transactionCount entries',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF24263A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFF3C774), size: 21),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your insight is ready',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF3C774),
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Get Pro'),
          ),
        ],
      ),
    );
  }
}
