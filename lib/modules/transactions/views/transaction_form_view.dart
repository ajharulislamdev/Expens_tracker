import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/currency_settings.dart';
import '../../../data/models/transaction_type.dart';
import '../controllers/transaction_form_controller.dart';

class TransactionFormView extends GetView<TransactionFormController> {
  const TransactionFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEdit ? 'Edit transaction' : 'Add transaction'),
        actions: [
          if (controller.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: controller.deleteCurrent,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Type ----
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.north_east),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.south_west),
                        ),
                      ],
                      selected: {controller.type.value},
                      onSelectionChanged: (s) => controller.setType(s.first),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith((st) {
                          if (st.contains(WidgetState.selected)) {
                            return controller.type.value ==
                                    TransactionType.income
                                ? AppColors.income
                                : AppColors.expense;
                          }
                          return null;
                        }),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),

              TextFormField(
                controller: controller.titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: controller.validateTitle,
              ),
              const SizedBox(height: 16),

              Obx(() => TextFormField(
                    controller: controller.amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: '${CurrencySettings.current.value.symbol} ',
                    ),
                    validator: controller.validateAmount,
                  )),
              const SizedBox(height: 16),

              Obx(() => DropdownButtonFormField<String>(
                    key: ValueKey(controller.type.value),
                    initialValue: controller.category.value,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: controller.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(children: [
                                Icon(AppConstants.iconFor(c), size: 20),
                                const SizedBox(width: 10),
                                Text(c),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.category.value = v;
                    },
                  )),
              const SizedBox(height: 16),

              Obx(() => InkWell(
                    onTap: controller.pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('EEE, d MMM y')
                          .format(controller.date.value)),
                    ),
                  )),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: controller.save,
                icon: const Icon(Icons.check),
                label: Text(controller.isEdit ? 'Update' : 'Save'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
