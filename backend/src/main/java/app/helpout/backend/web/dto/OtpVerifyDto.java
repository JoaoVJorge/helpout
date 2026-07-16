package app.helpout.backend.web.dto;

import jakarta.validation.constraints.NotBlank;

public record OtpVerifyDto(@NotBlank String phoneNumber, @NotBlank String code) {
}
