package app.helpout.backend.web.controller;

import app.helpout.backend.domain.service.AuthService;
import app.helpout.backend.web.dto.ApiResponse;
import app.helpout.backend.web.dto.AuthTokenResponseDto;
import app.helpout.backend.web.dto.OtpRequestDto;
import app.helpout.backend.web.dto.OtpVerifyDto;
import app.helpout.backend.web.dto.RefreshTokenRequestDto;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/otp/request")
    public ApiResponse<Void> requestOtp(@Valid @RequestBody OtpRequestDto request) {
        authService.requestOtp(request.phoneNumber());
        return ApiResponse.ok(null, "Code sent");
    }

    @PostMapping("/otp/verify")
    public ApiResponse<AuthTokenResponseDto> verifyOtp(@Valid @RequestBody OtpVerifyDto request) {
        return ApiResponse.ok(authService.verifyOtp(request.phoneNumber(), request.code()));
    }

    @PostMapping("/refresh")
    public ApiResponse<AuthTokenResponseDto> refresh(@Valid @RequestBody RefreshTokenRequestDto request) {
        return ApiResponse.ok(authService.refresh(request.refreshToken()));
    }
}
