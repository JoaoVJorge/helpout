package app.helpout.backend.web.dto;

public record UpdateUserProfileDto(
        String userName,
        String nickName,
        String email,
        String birthDate,
        Long accentColorValue,
        Integer avatarIconIndex,
        Boolean notificationsEnabled,
        String languageCode,
        Boolean isDarkMode) {
}
