package app.helpout.backend.web.controller;

import app.helpout.backend.domain.service.UserService;
import app.helpout.backend.web.dto.ApiResponse;
import app.helpout.backend.web.dto.UpdateUserProfileDto;
import app.helpout.backend.web.dto.UserProfileDto;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ApiResponse<UserProfileDto> getMe(@AuthenticationPrincipal UUID userId) {
        return ApiResponse.ok(userService.getProfile(userId));
    }

    @PutMapping("/me")
    public ApiResponse<UserProfileDto> updateMe(
            @AuthenticationPrincipal UUID userId, @RequestBody UpdateUserProfileDto request) {
        return ApiResponse.ok(userService.updateProfile(userId, request));
    }
}
