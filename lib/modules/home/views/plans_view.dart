import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/plan_model.dart';
import '../controllers/plans_controller.dart';

class PlansView extends GetView<PlansController> {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals & budgets')),
      body: Obx(() {
        final goals = controller.goals;
        final budgets = controller.budgets;
        final goalTarget = goals.fold<double>(
          0,
          (total, goal) => total + goal.targetAmount,
        );
        final goalSaved = goals.fold<double>(
          0,
          (total, goal) => total + goal.currentAmount,
        );
        final budgetLimit = budgets.fold<double>(
          0,
          (total, budget) => total + budget.targetAmount,
        );
        final budgetSpent = budgets.fold<double>(
          0,
          (total, budget) => total + budget.currentAmount,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _OverviewCard(
                        title: 'Saved for goals',
                        amount: goalSaved,
                        detail:
                            'of ${CurrencyFormatter.format(goalTarget)} target',
                        progress: goalTarget == 0
                            ? 0
                            : (goalSaved / goalTarget).clamp(0.0, 1.0),
                        color: AppColors.chartPurple,
                        icon: Icons.flag_rounded,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _OverviewCard(
                        title: 'Monthly budgets',
                        amount: budgetSpent,
                        detail:
                            'of ${CurrencyFormatter.format(budgetLimit)} limit',
                        progress: budgetLimit == 0
                            ? 0
                            : (budgetSpent / budgetLimit).clamp(0.0, 1.0),
                        color: budgetLimit > 0 && budgetSpent > budgetLimit
                            ? AppColors.expense
                            : AppColors.chartBlue,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Savings goals',
              onAdd: () => _editPlan(context, PlanType.goal),
              addLabel: 'Add goal',
            ),
            const SizedBox(height: 10),
            if (goals.isEmpty)
              _EmptyPlansCard(
                message: 'No savings goals yet. Create one to start tracking.',
                onAdd: () => _editPlan(context, PlanType.goal),
              )
            else
              ...goals.map(
                (goal) => _GoalCard(
                  goal: goal,
                  onEdit: () => _editPlan(context, PlanType.goal, goal),
                  onDelete: () => _deletePlan(context, goal),
                ),
              ),
            const SizedBox(height: 18),
            _SectionHeading(
              title: 'Monthly budgets',
              onAdd: () => _editPlan(context, PlanType.budget),
              addLabel: 'Add budget',
            ),
            const SizedBox(height: 10),
            if (budgets.isEmpty)
              _EmptyPlansCard(
                message: 'No budgets yet. Add one to keep spending on track.',
                onAdd: () => _editPlan(context, PlanType.budget),
              )
            else
              ...budgets.map(
                (budget) => _BudgetCard(
                  budget: budget,
                  onEdit: () => _editPlan(context, PlanType.budget, budget),
                  onDelete: () => _deletePlan(context, budget),
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _editPlan(
    BuildContext context,
    PlanType type, [
    PlanModel? existing,
  ]) async {
    final plan = await showDialog<PlanModel>(
      context: context,
      builder: (_) => _PlanEditorDialog(type: type, existing: existing),
    );
    if (plan == null) return;

    await controller.save(plan);
    SnackbarHelper.success(
      existing == null
          ? type == PlanType.goal
              ? 'Savings goal added'
              : 'Budget added'
          : type == PlanType.goal
              ? 'Savings goal updated'
              : 'Budget updated',
    );
  }

  Future<void> _deletePlan(BuildContext context, PlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('Delete ${plan.type == PlanType.goal ? 'goal' : 'budget'}?'),
        content: Text('"${plan.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.delete(plan.id);
    SnackbarHelper.success('Plan deleted');
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.amount,
    required this.detail,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String title;
  final double amount;
  final String detail;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.onAdd,
    required this.addLabel,
  });

  final String title;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _EmptyPlansCard extends StatelessWidget {
  const _EmptyPlansCard({required this.message, required this.onAdd});

  final String message;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.track_changes, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add plan',
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanModel goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final remaining =
        (goal.targetAmount - goal.currentAmount).clamp(0.0, goal.targetAmount);
    final theme = Theme.of(context);
    const goalColor = AppColors.chartPurple;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.chartPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(goal.targetAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _PlanMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${(goal.progress * 100).round()}% saved',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: goalColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${CurrencyFormatter.format(goal.currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  color: goalColor,
                  backgroundColor: goalColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                remaining == 0
                    ? 'Goal completed'
                    : '${CurrencyFormatter.format(remaining)} left to reach your goal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanModel budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final percent = (budget.progress * 100).round();
    final isOverBudget = budget.currentAmount > budget.targetAmount;
    final progressColor =
        isOverBudget ? AppColors.expense : AppColors.chartBlue;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(_budgetIcon(budget.name), color: progressColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(budget.currentAmount)} spent',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(budget.targetAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _PlanMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    '$percent% used',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${CurrencyFormatter.format(budget.currentAmount)} of ${CurrencyFormatter.format(budget.targetAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: budget.progress,
                  minHeight: 8,
                  color: progressColor,
                  backgroundColor: progressColor.withValues(alpha: 0.1),
                ),
              ),
              if (isOverBudget) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Over budget by ${CurrencyFormatter.format(budget.currentAmount - budget.targetAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

IconData _budgetIcon(String name) {
  final normalizedName = name.toLowerCase();
  if (normalizedName.contains('car')) return Icons.directions_car;
  if (normalizedName.contains('education') ||
      normalizedName.contains('school')) {
    return Icons.school_outlined;
  }
  if (normalizedName.contains('vacation') ||
      normalizedName.contains('travel')) {
    return Icons.luggage_outlined;
  }
  if (normalizedName.contains('food')) return Icons.restaurant;
  if (normalizedName.contains('home') || normalizedName.contains('house')) {
    return Icons.home_outlined;
  }
  if (normalizedName.contains('health')) return Icons.medical_services;
  if (normalizedName.contains('transport')) return Icons.directions_bus;
  return Icons.account_balance_wallet_outlined;
}

class _PlanMenu extends StatelessWidget {
  const _PlanMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Plan options',
      onSelected: (action) {
        if (action == 'edit') onEdit();
        if (action == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _PlanEditorDialog extends StatefulWidget {
  const _PlanEditorDialog({required this.type, this.existing});

  final PlanType type;
  final PlanModel? existing;

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _currentController;

  bool get _isGoal => widget.type == PlanType.goal;

  @override
  void initState() {
    super.initState();
    final plan = widget.existing;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _targetController = TextEditingController(
      text: plan?.targetAmount.toString() ?? '',
    );
    _currentController = TextEditingController(
      text: plan?.currentAmount.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  double? _parseAmount(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', ''));

  String? _validateAmount(String? value, {required bool allowZero}) {
    final amount = _parseAmount(value);
    if (amount == null || !amount.isFinite) return 'Enter a valid amount';
    if (allowZero ? amount < 0 : amount <= 0) {
      return allowZero
          ? 'Amount cannot be negative'
          : 'Amount must be greater than 0';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      PlanModel(
        id: existing?.id ?? PlanModel.generateId(),
        name: _nameController.text.trim(),
        targetAmount: _parseAmount(_targetController.text)!,
        currentAmount: _parseAmount(_currentController.text)!,
        type: widget.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isGoal ? 'savings goal' : 'monthly budget';

    return AlertDialog(
      title: Text(
        '${widget.existing == null ? 'Add' : 'Edit'} $title',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: _isGoal ? 'Target amount' : 'Monthly limit',
                ),
                validator: (value) => _validateAmount(value, allowZero: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: _isGoal ? 'Amount saved so far' : 'Amount spent',
                ),
                validator: (value) => _validateAmount(value, allowZero: true),
              ),
              const SizedBox(height: 8),
              Text(
                _isGoal
                    ? 'Progress is saved on this device and can be edited anytime.'
                    : 'Budget spending is entered manually and saved on this device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
