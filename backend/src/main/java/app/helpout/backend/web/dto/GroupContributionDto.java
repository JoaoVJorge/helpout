package app.helpout.backend.web.dto;

public record GroupContributionDto(String groupId, int todaySeconds, int weekSeconds, int monthSeconds) {
}
