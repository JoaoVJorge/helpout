package app.helpout.backend.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record CreateGroupRequestDto(
        @NotBlank String name, @NotBlank String theme, @NotEmpty List<String> memberIds) {
}
