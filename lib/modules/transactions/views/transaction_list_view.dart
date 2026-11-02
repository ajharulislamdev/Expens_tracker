import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../controllers/transaction_controller.dart';
import '../widgets/transaction_tile.dart';

class TransactionListView extends GetView<TransactionController> {
  const TransactionListView({super.key});

  static const String _allCategories = '__all__';

  Future<bool> _confirmDelete(String title) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('"$title" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM y');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (v) => controller.sortOption.value = v,
            itemBuilder: (_) => SortOption.values
                .map((o) => PopupMenuItem(value: o, child: Text(o.label)))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Search ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Search title or category',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),

          // ---- Filters ----
          SizedBox(
            height: 44,
            child: Obx(() {
              final type = controller.filterType.value;
              final range = controller.filterRange.value;
              final cat = controller.filterCategory.value;
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('All', type == null,
                      () => controller.filterType.value = null),
                  _chip(
                      'Expense',
                      type == TransactionType.expense,
                      () => controller.filterType.value =
                          TransactionType.expense),
                  _chip(
                      'Income',
                      type == TransactionType.income,
                      () =>
                          controller.filterType.value = TransactionType.income),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(range == null
                          ? 'Date range'
                          : '${dateFmt.format(range.start)} - ${dateFmt.format(range.end)}'),
                      onPressed: controller.pickFilterRange,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PopupMenuButton<String>(
                      // A null value would never trigger onSelected, so use a sentinel.
                      onSelected: (v) => controller.filterCategory.value =
                          v == _allCategories ? null : v,
                      itemBuilder: (_) => [
                        const PopupMenuItem<String>(
                            value: _allCategories,
                            child: Text('All categories')),
                        ...controller.usedCategories.map((c) =>
                            PopupMenuItem<String>(value: c, child: Text(c))),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.category, size: 18),
                        label: Text(cat ?? 'Category'),
                      ),
                    ),
                  ),
                  if (controller.hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                        onPressed: controller.clearFilters,
                      ),
                    ),
                ],
              );
            }),
          ),

          // ---- List ----
          Expanded(
            child: Obx(() {
              final list = controller.filtered;
              final s = TransactionRepository.summarize(list);

              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.all.isEmpty
                        ? 'No transactions yet'
                        : 'No transactions match your filters',
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s.count} items',
                            style: Theme.of(context).textTheme.labelMedium),
                        Obx(
                          () => Text(
                            '+${CurrencyFormatter.format(s.income)}',
                            style: const TextStyle(
                                color: AppColors.income,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Obx(
                          () => Text(
                            '-${CurrencyFormatter.format(s.expense)}',
                            style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = list[i];
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: AppColors.expense,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) => _confirmDelete(t.title),
                          onDismissed: (_) => controller.delete(t),
                          child: TransactionTile(
                            tx: t,
                            onTap: () =>
                                Get.toNamed(AppRoutes.form, arguments: t),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
