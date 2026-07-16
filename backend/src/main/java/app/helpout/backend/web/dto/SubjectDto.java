package app.helpout.backend.web.dto;

public record SubjectDto(
        String id,
        String name,
        String category,
        long colorValue,
        int totalSeconds,
        int goalSeconds,
        int currentPages,
        int goalPages,
        String notes,
        String iconName,
        int restMinutes,
        int wallpaperIndex,
        boolean deleted) {
}
