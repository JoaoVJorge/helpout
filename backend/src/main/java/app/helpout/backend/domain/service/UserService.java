package app.helpout.backend.domain.service;

import app.helpout.backend.web.dto.UpdateUserProfileDto;
import app.helpout.backend.web.dto.UserProfileDto;
import java.util.UUID;

public interface UserService {

    UserProfileDto getProfile(UUID userId);

    UserProfileDto updateProfile(UUID userId, UpdateUserProfileDto request);
}
