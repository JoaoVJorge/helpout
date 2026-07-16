package app.helpout.backend.web.dto;

import jakarta.validation.constraints.NotBlank;

public record OtpRequestDto(@NotBlank String phoneNumber) {
}
