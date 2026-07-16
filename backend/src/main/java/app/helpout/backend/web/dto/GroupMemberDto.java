package app.helpout.backend.web.dto;

public record GroupMemberDto(
        String id,
        String name,
        long avatarColorValue,
        int todaySeconds,
        int weekSeconds,
        int monthSeconds,
        String role) {
}
