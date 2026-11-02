import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_type.dart';
import '../controllers/report_controller.dart';
import '../widgets/analytics_donut_chart.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  static const _categoryColors = [
    AppColors.chartPurple,
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartOrange,
  ];

  static const _presetLabels = {
    ReportPreset.thisWeek: 'This week',
    ReportPreset.thisMonth: 'This month',
    ReportPreset.lastMonth: 'Last month',
    ReportPreset.thisYear: 'This year',
    ReportPreset.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y');

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Obx(() {
        final colorScheme = Theme.of(context).colorScheme;
        final summary = controller.summary;
        final selectedType =
            controller.typeFilter.value ?? TransactionType.expense;
        final isExpense = selectedType == TransactionType.expense;
        final total = isExpense ? summary.expense : summary.income;
        final categories = controller.categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final previous = controller.comparisonCategoryTotals;
        final colors = List<Color>.generate(categories.length, (index) {
          return _categoryColors[index % _categoryColors.length];
        });
        final isExporting = controller.isExporting.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 112),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expenses'),
                  icon: Icon(Icons.south_east_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.north_east_rounded),
                ),
              ],
              selected: {selectedType},
              onSelectionChanged: (value) =>
                  controller.typeFilter.value = value.first,
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 10),
            AnalyticsDonutChart(
              title: isExpense ? 'Total Expenses' : 'Total Income',
              amount: total,
              values: categories.map((entry) => entry.value).toList(),
              colors: colors,
            ),
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isExpense ? 'All Expenses' : 'All Income',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Text(
                    'Total ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Obx(
                    () => Text(
                      CurrencyFormatter.format(total),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Center(
                    child: Text(
                      'No ${isExpense ? 'expenses' : 'income'} in this period yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final previousAmount = previous[category.key];
                final change = previousAmount == null || previousAmount == 0
                    ? null
                    : (category.value - previousAmount) / previousAmount * 100;
                return _CategoryBreakdownTile(
                  category: category.key,
                  amount: category.value,
                  proportion: total == 0 ? 0 : category.value / total,
                  color: colors[index],
                  change: change,
                  comparisonLabel: controller.comparisonLabel,
                );
              }),
            const SizedBox(height: 16),
            Text(
              'Report period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ReportPreset.values
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_presetLabels[preset]!),
                      selected: controller.preset.value == preset,
                      onSelected: (_) => controller.applyPreset(preset),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(controller.from.value)} – ${dateFormat.format(controller.to.value)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isExporting ? null : controller.exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export PDF'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isExporting ? null : controller.exportExcel,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export Excel'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            if (isExporting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 12),
            Text(
              'Reports are saved to Download/${AppConstants.exportFolder}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        );
      }),
    );
  }
}

class _CategoryBreakdownTile extends StatelessWidget {
  const _CategoryBreakdownTile({
    required this.category,
    required this.amount,
    required this.proportion,
    required this.color,
    required this.change,
    required this.comparisonLabel,
  });

  final String category;
  final double amount;
  final double proportion;
  final Color color;
  final double? change;
  final String comparisonLabel;

  @override
  Widget build(BuildContext context) {
    final difference = change;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final changeColor = difference == null
        ? muted
        : difference >= 0
            ? AppColors.income
            : AppColors.expense;
    final changeLabel = difference == null
        ? 'New'
        : '${difference > 0 ? '+' : ''}${difference.round()}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: isLight ? 0.48 : 0.25,
              ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    AppConstants.iconFor(category),
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(proportion * 100).round()}% of total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Obx(
                      () => Text(
                        CurrencyFormatter.format(amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    changeLabel,
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  comparisonLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: proportion.clamp(0, 1),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
