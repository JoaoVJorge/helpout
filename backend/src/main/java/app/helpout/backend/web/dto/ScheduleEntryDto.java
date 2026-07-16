package app.helpout.backend.web.dto;

public record ScheduleEntryDto(
        String id,
        String title,
        int weekday,
        int startMinutes,
        Integer endMinutes,
        long colorValue,
        boolean deleted) {
}
