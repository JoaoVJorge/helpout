package app.helpout.backend.domain.service.impl;

import app.helpout.backend.domain.exception.NotFoundException;
import app.helpout.backend.domain.model.User;
import app.helpout.backend.domain.repository.UserRepository;
import app.helpout.backend.domain.service.UserService;
import app.helpout.backend.web.dto.UpdateUserProfileDto;
import app.helpout.backend.web.dto.UserProfileDto;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public UserProfileDto getProfile(UUID userId) {
        return toDto(findUser(userId));
    }

    @Override
    @Transactional
    public UserProfileDto updateProfile(UUID userId, UpdateUserProfileDto request) {
        User user = findUser(userId);

        if (request.userName() != null) {
            user.setUserName(request.userName());
        }
        if (request.nickName() != null) {
            user.setNickName(request.nickName());
        }
        if (request.email() != null) {
            user.setEmail(request.email());
        }
        if (request.birthDate() != null && !request.birthDate().isBlank()) {
            user.setBirthDate(LocalDate.parse(request.birthDate()));
        }
        if (request.accentColorValue() != null) {
            user.setAccentColorValue(request.accentColorValue());
        }
        if (request.avatarIconIndex() != null) {
            user.setAvatarIconIndex(request.avatarIconIndex());
        }
        if (request.notificationsEnabled() != null) {
            user.setNotificationsEnabled(request.notificationsEnabled());
        }
        if (request.languageCode() != null) {
            user.setLanguageCode(request.languageCode());
        }
        if (request.isDarkMode() != null) {
            user.setDarkMode(request.isDarkMode());
        }

        return toDto(userRepository.save(user));
    }

    private User findUser(UUID userId) {
        return userRepository.findById(userId).orElseThrow(() -> new NotFoundException("User not found"));
    }

    private static UserProfileDto toDto(User user) {
        return new UserProfileDto(
                user.getUserName(),
                user.getNickName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getBirthDate() == null ? null : user.getBirthDate().toString(),
                user.getAccentColorValue(),
                user.getAvatarIconIndex(),
                user.isNotificationsEnabled(),
                user.getLanguageCode(),
                user.isDarkMode());
    }
}
