import "dart:convert";

import "package:help_out/core/data/http_requests/sync_http_requests.dart";
import "package:help_out/core/data/repositories/daily_tasks_repository.dart";
import "package:help_out/core/data/repositories/schedule_repository.dart";
import "package:help_out/core/data/repositories/subjects_repository.dart";
import "package:help_out/core/domain/entities/daily_task_entity.dart";
import "package:help_out/core/domain/entities/schedule_entry_entity.dart";
import "package:help_out/core/domain/entities/subject_entity.dart";
import "package:help_out/core/domain/enums/time_category_type.dart";
import "package:help_out/core/services/http/http_client_service.dart";
import "package:help_out/core/services/local_storage/app_local_storage_service.dart";
import "package:help_out/core/services/local_storage/local_storage_keys.dart";

/// Keeps subjects, daily tasks and schedule entries in sync with the backend
/// while the app stays local-first: local storage is always read/written
/// first for instant UI, this just reconciles with the server in the
/// background in a couple of batched calls (a pull and a push), not one call
/// per action.
class SyncService {
  SyncService({
    required this._httpClientService,
    required this._subjectsRepository,
    required this._dailyTasksRepository,
    required this._scheduleRepository,
    required this._localStorageService,
  });

  final HttpClientService _httpClientService;
  final SubjectsRepository _subjectsRepository;
  final DailyTasksRepository _dailyTasksRepository;
  final ScheduleRepository _scheduleRepository;
  final AppLocalStorageService _localStorageService;

  bool _isSyncing = false;

  Future<void> pull() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      final String? since = await _localStorageService.read<String?>(LocalStorageKeys.lastSyncedAt);
      final result = await _httpClientService.request(SyncPullHttpRequest(since: since));

      await result.fold((_) async {}, (data) async {
        await _mergeSubjects(data["subjects"] as List<dynamic>? ?? []);
        await _mergeDailyTasks(data["dailyTasks"] as List<dynamic>? ?? []);
        await _mergeScheduleEntries(data["scheduleEntries"] as List<dynamic>? ?? []);

        final String? syncedAt = data["syncedAt"] as String?;
        if (syncedAt != null) {
          await _localStorageService.write(LocalStorageKeys.lastSyncedAt, syncedAt);
        }
      });
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> push() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      final List<SubjectEntity> subjects = await _currentSubjects();
      final List<DailyTaskEntity> dailyTasks = await _currentDailyTasks();
      final List<ScheduleEntryEntity> scheduleEntries = await _currentScheduleEntries();

      final List<Map<String, dynamic>> subjectPayload = await _diffPayload(
        key: LocalStorageKeys.lastPushedSubjectIds,
        currentIds: subjects.map((subject) => subject.id).toSet(),
        activeEntries: subjects.map((subject) => {...subject.toMap(), "deleted": false}),
      );
      final List<Map<String, dynamic>> dailyTaskPayload = await _diffPayload(
        key: LocalStorageKeys.lastPushedDailyTaskIds,
        currentIds: dailyTasks.map((task) => task.id).toSet(),
        activeEntries: dailyTasks.map((task) => {...task.toMap(), "deleted": false}),
      );
      final List<Map<String, dynamic>> scheduleEntryPayload = await _diffPayload(
        key: LocalStorageKeys.lastPushedScheduleEntryIds,
        currentIds: scheduleEntries.map((entry) => entry.id).toSet(),
        activeEntries: scheduleEntries.map((entry) => {...entry.toMap(), "deleted": false}),
      );

      if (subjectPayload.isEmpty && dailyTaskPayload.isEmpty && scheduleEntryPayload.isEmpty) {
        return;
      }

      await _httpClientService.request(
        SyncPushHttpRequest(
          payload: {
            "subjects": subjectPayload,
            "dailyTasks": dailyTaskPayload,
            "scheduleEntries": scheduleEntryPayload,
            "groupContributions": const <Map<String, dynamic>>[],
          },
        ),
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> _diffPayload({
    required LocalStorageKeys key,
    required Set<String> currentIds,
    required Iterable<Map<String, dynamic>> activeEntries,
  }) async {
    final Set<String> previousIds = await _readIdSet(key);
    final Set<String> deletedIds = previousIds.difference(currentIds);

    await _localStorageService.write(key, jsonEncode(currentIds.toList()));

    return [
      ...activeEntries,
      for (final String id in deletedIds) {"id": id, "deleted": true},
    ];
  }

  Future<Set<String>> _readIdSet(LocalStorageKeys key) async {
    final String? saved = await _localStorageService.read<String?>(key);
    if (saved == null) {
      return {};
    }
    return (jsonDecode(saved) as List<dynamic>).cast<String>().toSet();
  }

  Future<List<SubjectEntity>> _currentSubjects() => _subjectsRepository.getSubjects().then(
    (result) => result.fold((_) => <SubjectEntity>[], (subjects) => subjects),
  );

  Future<List<DailyTaskEntity>> _currentDailyTasks() => _dailyTasksRepository.getTasks().then(
    (result) => result.fold((_) => <DailyTaskEntity>[], (tasks) => tasks),
  );

  Future<List<ScheduleEntryEntity>> _currentScheduleEntries() => _scheduleRepository.getEntries().then(
    (result) => result.fold((_) => <ScheduleEntryEntity>[], (entries) => entries),
  );

  Future<void> _mergeSubjects(List<dynamic> remote) async {
    if (remote.isEmpty) {
      return;
    }
    final List<SubjectEntity> local = await _currentSubjects();
    final Map<String, SubjectEntity> byId = {for (final subject in local) subject.id: subject};

    for (final dynamic item in remote) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final String id = map["id"] as String;
      if (map["deleted"] == true) {
        byId.remove(id);
        continue;
      }
      byId[id] = SubjectEntity(
        id: id,
        name: map["name"] as String,
        category: TimeCategoryType.values.byName(map["category"] as String),
        colorValue: map["colorValue"] as int,
        totalSeconds: map["totalSeconds"] as int,
        goalSeconds: map["goalSeconds"] as int? ?? 0,
        currentPages: map["currentPages"] as int? ?? 0,
        goalPages: map["goalPages"] as int? ?? 0,
        notes: map["notes"] as String? ?? "",
        iconName: map["iconName"] as String? ?? "",
        restMinutes: map["restMinutes"] as int? ?? SubjectEntity.defaultRestMinutes,
        wallpaperIndex: map["wallpaperIndex"] as int? ?? 0,
      );
    }

    await _subjectsRepository.saveSubjects(byId.values.toList());
  }

  Future<void> _mergeDailyTasks(List<dynamic> remote) async {
    if (remote.isEmpty) {
      return;
    }
    final List<DailyTaskEntity> local = await _currentDailyTasks();
    final Map<String, DailyTaskEntity> byId = {for (final task in local) task.id: task};

    for (final dynamic item in remote) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final String id = map["id"] as String;
      if (map["deleted"] == true) {
        byId.remove(id);
        continue;
      }
      byId[id] = DailyTaskEntity.fromMap(map);
    }

    await _dailyTasksRepository.saveTasks(byId.values.toList());
  }

  Future<void> _mergeScheduleEntries(List<dynamic> remote) async {
    if (remote.isEmpty) {
      return;
    }
    final List<ScheduleEntryEntity> local = await _currentScheduleEntries();
    final Map<String, ScheduleEntryEntity> byId = {for (final entry in local) entry.id: entry};

    for (final dynamic item in remote) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final String id = map["id"] as String;
      if (map["deleted"] == true) {
        byId.remove(id);
        continue;
      }
      byId[id] = ScheduleEntryEntity.fromMap(map);
    }

    await _scheduleRepository.saveEntries(byId.values.toList());
  }
}
