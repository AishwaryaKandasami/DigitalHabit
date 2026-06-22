import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../domain/plan_model.dart';

class PlanRepository {
  final FirebaseFirestore _firestore;

  PlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create or update a plan.
  Future<PlanModel> savePlan(String familyId, PlanModel plan) async {
    if (plan.id.isEmpty) {
      // Create new
      final docRef =
          _firestore.collection(FirestorePaths.plans(familyId)).doc();
      final newPlan = PlanModel(
        id: docRef.id,
        memberId: plan.memberId,
        weekStart: plan.weekStart,
        status: plan.status,
        parentNote: plan.parentNote,
        submittedAt: plan.submittedAt,
        reviewedAt: plan.reviewedAt,
        days: plan.days,
      );
      await docRef.set(newPlan.toMap());
      return newPlan;
    } else {
      // Update existing
      await _firestore
          .collection(FirestorePaths.plans(familyId))
          .doc(plan.id)
          .set(plan.toMap());
      return plan;
    }
  }

  /// Get plan for a specific member and week.
  Future<PlanModel?> getPlanForWeek(
    String familyId,
    String memberId,
    String weekStart,
  ) async {
    final query = await _firestore
        .collection(FirestorePaths.plans(familyId))
        .where('memberId', isEqualTo: memberId)
        .where('weekStart', isEqualTo: weekStart)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return PlanModel.fromMap(doc.id, doc.data());
  }

  /// Stream plan for a specific member and week.
  Stream<PlanModel?> streamPlanForWeek(
    String familyId,
    String memberId,
    String weekStart,
  ) {
    return _firestore
        .collection(FirestorePaths.plans(familyId))
        .where('memberId', isEqualTo: memberId)
        .where('weekStart', isEqualTo: weekStart)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return PlanModel.fromMap(doc.id, doc.data());
    });
  }

  /// Stream all plans for a family (grown-up history view).
  Stream<List<PlanModel>> streamAllPlans(String familyId) {
    return _firestore
        .collection(FirestorePaths.plans(familyId))
        .orderBy('weekStart', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlanModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}
