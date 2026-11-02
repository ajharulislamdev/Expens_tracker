import '../models/plan_model.dart';
import '../providers/hive_provider.dart';

class PlanRepository {
  PlanRepository(this._provider);

  final HiveProvider _provider;

  List<PlanModel> getAll() => _provider.planBox.values.toList();

  Future<void> save(PlanModel plan) => _provider.planBox.put(plan.id, plan);

  Future<void> delete(String id) => _provider.planBox.delete(id);
}
