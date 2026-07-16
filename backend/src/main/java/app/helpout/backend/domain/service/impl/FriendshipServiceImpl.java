package app.helpout.backend.domain.service.impl;

import app.helpout.backend.domain.exception.BusinessValidationException;
import app.helpout.backend.domain.exception.NotFoundException;
import app.helpout.backend.domain.model.Friendship;
import app.helpout.backend.domain.model.User;
import app.helpout.backend.domain.repository.FriendshipRepository;
import app.helpout.backend.domain.repository.UserRepository;
import app.helpout.backend.domain.service.FriendshipService;
import app.helpout.backend.web.dto.FriendDto;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class FriendshipServiceImpl implements FriendshipService {

    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;

    public FriendshipServiceImpl(FriendshipRepository friendshipRepository, UserRepository userRepository) {
        this.friendshipRepository = friendshipRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<FriendDto> listFriends(UUID userId) {
        return friendshipRepository.findByUserId(userId).stream()
                .map(friendship -> toDto(friendship.getFriend()))
                .toList();
    }

    @Override
    @Transactional
    public FriendDto addFriend(UUID userId, String friendPhoneNumber) {
        User user = userRepository.findById(userId).orElseThrow(() -> new NotFoundException("User not found"));
        User friend = userRepository
                .findByPhoneNumber(friendPhoneNumber)
                .orElseThrow(() -> new NotFoundException("No account found for that phone number"));

        if (friend.getId().equals(user.getId())) {
            throw new BusinessValidationException("You can't add yourself as a friend");
        }

        if (!friendshipRepository.existsByUserIdAndFriendId(user.getId(), friend.getId())) {
            friendshipRepository.save(new Friendship(user, friend));
            friendshipRepository.save(new Friendship(friend, user));
        }

        return toDto(friend);
    }

    private static FriendDto toDto(User user) {
        String name = user.getNickName() != null && !user.getNickName().isBlank()
                ? user.getNickName()
                : user.getUserName();
        return new FriendDto(user.getId().toString(), name);
    }
}
