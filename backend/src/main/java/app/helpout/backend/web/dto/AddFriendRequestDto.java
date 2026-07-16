package app.helpout.backend.web.dto;

import jakarta.validation.constraints.NotBlank;

public record AddFriendRequestDto(@NotBlank String phoneNumber) {
}
