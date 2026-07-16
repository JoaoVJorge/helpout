package app.helpout.backend.web.controller;

import app.helpout.backend.domain.service.FriendshipService;
import app.helpout.backend.web.dto.AddFriendRequestDto;
import app.helpout.backend.web.dto.ApiResponse;
import app.helpout.backend.web.dto.FriendDto;
import app.helpout.backend.web.dto.FriendListDto;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/friends")
public class FriendController {

    private final FriendshipService friendshipService;

    public FriendController(FriendshipService friendshipService) {
        this.friendshipService = friendshipService;
    }

    @GetMapping
    public ApiResponse<FriendListDto> list(@AuthenticationPrincipal UUID userId) {
        return ApiResponse.ok(new FriendListDto(friendshipService.listFriends(userId)));
    }

    @PostMapping
    public ApiResponse<FriendDto> add(
            @AuthenticationPrincipal UUID userId, @Valid @RequestBody AddFriendRequestDto request) {
        return ApiResponse.ok(friendshipService.addFriend(userId, request.phoneNumber()));
    }
}
