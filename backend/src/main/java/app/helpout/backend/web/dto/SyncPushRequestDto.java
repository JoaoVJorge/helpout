package app.helpout.backend.web.dto;

import java.util.List;

public record SyncPushRequestDto(
        List<SubjectDto> subjects,
        List<DailyTaskDto> dailyTasks,
        List<ScheduleEntryDto> scheduleEntries,
        List<GroupContributionDto> groupContributions) {
}
