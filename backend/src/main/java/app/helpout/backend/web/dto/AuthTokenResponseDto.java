package app.helpout.backend.web.dto;

public record AuthTokenResponseDto(String accessToken, String refreshToken, boolean hasProfile) {
}
