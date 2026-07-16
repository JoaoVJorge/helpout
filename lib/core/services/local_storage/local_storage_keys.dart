enum LocalStorageKeys {
  appConfig(hasSensitiveData: false),
  subjects(hasSensitiveData: false),
  dailyTasks(hasSensitiveData: false),
  lastActivity(hasSensitiveData: false),
  dailyProgress(hasSensitiveData: false),
  scheduleEntries(hasSensitiveData: false),
  accessToken(hasSensitiveData: true),
  refreshToken(hasSensitiveData: true),
  lastSyncedAt(hasSensitiveData: false),
  lastPushedSubjectIds(hasSensitiveData: false),
  lastPushedDailyTaskIds(hasSensitiveData: false),
  lastPushedScheduleEntryIds(hasSensitiveData: false);

  const LocalStorageKeys({required this.hasSensitiveData});

  final bool hasSensitiveData;
}
