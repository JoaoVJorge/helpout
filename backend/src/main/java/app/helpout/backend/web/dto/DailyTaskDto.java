package app.helpout.backend.web.dto;

import java.util.List;

public record DailyTaskDto(
        String id,
        String name,
        long colorValue,
        int targetDays,
        List<String> completedDates,
        boolean deleted) {
}
