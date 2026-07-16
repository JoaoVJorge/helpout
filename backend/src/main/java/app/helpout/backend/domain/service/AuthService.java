package app.helpout.backend.domain.service;

import app.helpout.backend.web.dto.AuthTokenResponseDto;

public interface AuthService {

    void requestOtp(String phoneNumber);

    AuthTokenResponseDto verifyOtp(String phoneNumber, String code);

    AuthTokenResponseDto refresh(String refreshToken);
}
