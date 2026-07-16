package app.helpout.backend.web.controller;

import app.helpout.backend.domain.service.GroupService;
import app.helpout.backend.web.dto.ApiResponse;
import app.helpout.backend.web.dto.CreateGroupRequestDto;
import app.helpout.backend.web.dto.GroupDto;
import app.helpout.backend.web.dto.GroupListDto;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/groups")
public class GroupController {

    private final GroupService groupService;

    public GroupController(GroupService groupService) {
        this.groupService = groupService;
    }

    @GetMapping
    public ApiResponse<GroupListDto> list(@AuthenticationPrincipal UUID userId) {
        return ApiResponse.ok(new GroupListDto(groupService.listGroups(userId)));
    }

    @PostMapping
    public ApiResponse<GroupDto> create(
            @AuthenticationPrincipal UUID userId, @Valid @RequestBody CreateGroupRequestDto request) {
        return ApiResponse.ok(groupService.createGroup(userId, request));
    }
}
