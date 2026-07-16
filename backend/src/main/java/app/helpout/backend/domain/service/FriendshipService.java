package app.helpout.backend.domain.service;

import app.helpout.backend.web.dto.FriendDto;
import java.util.List;
import java.util.UUID;

public interface FriendshipService {

    List<FriendDto> listFriends(UUID userId);

    FriendDto addFriend(UUID userId, String friendPhoneNumber);
}
