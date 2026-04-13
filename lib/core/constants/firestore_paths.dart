class FirestorePaths {
  FirestorePaths._();

  static const families = 'families';

  static String family(String familyId) => 'families/$familyId';

  static String members(String familyId) =>
      'families/$familyId/members';

  static String member(String familyId, String memberId) =>
      'families/$familyId/members/$memberId';

  static String plans(String familyId) =>
      'families/$familyId/plans';

  static String plan(String familyId, String planId) =>
      'families/$familyId/plans/$planId';

  static String taskLogs(String familyId) =>
      'families/$familyId/taskLogs';

  static String taskLog(String familyId, String logId) =>
      'families/$familyId/taskLogs/$logId';

  static String shopItems(String familyId) =>
      'families/$familyId/shopItems';

  static String transactions(String familyId) =>
      'families/$familyId/transactions';
}
