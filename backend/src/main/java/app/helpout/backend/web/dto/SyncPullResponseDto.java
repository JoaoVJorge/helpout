package app.helpout.backend.web.dto;

import java.util.List;

public record SyncPullResponseDto(
        List<SubjectDto> subjects,
        List<DailyTaskDto> dailyTasks,
        List<ScheduleEntryDto> scheduleEntries,
        List<GroupDto> groups,
        String syncedAt) {
}
