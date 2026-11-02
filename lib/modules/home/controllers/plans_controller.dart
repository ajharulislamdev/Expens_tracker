import 'package:get/get.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/repositories/plan_repository.dart';

class PlansController extends GetxController {
  PlansController(this._repository);

  final PlanRepository _repository;
  final RxList<PlanModel> plans = <PlanModel>[].obs;

  List<PlanModel> get goals =>
      plans.where((plan) => plan.type == PlanType.goal).toList();

  List<PlanModel> get budgets =>
      plans.where((plan) => plan.type == PlanType.budget).toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() => plans.assignAll(_repository.getAll());

  Future<void> save(PlanModel plan) async {
    await _repository.save(plan);
    final index = plans.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      plans.add(plan);
    } else {
      plans[index] = plan;
    }
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    plans.removeWhere((plan) => plan.id == id);
  }
}
