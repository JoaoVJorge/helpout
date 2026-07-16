package app.helpout.backend.web.dto;

public record UserProfileDto(
        String userName,
        String nickName,
        String email,
        String phoneNumber,
        String birthDate,
        long accentColorValue,
        int avatarIconIndex,
        boolean notificationsEnabled,
        String languageCode,
        boolean isDarkMode) {
}
