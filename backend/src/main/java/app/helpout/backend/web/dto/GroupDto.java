package app.helpout.backend.web.dto;

import java.util.List;

public record GroupDto(
        String id,
        String name,
        String theme,
        List<GroupMemberDto> members,
        String ownerId,
        String createdAt,
        String inviteCode,
        String privacy) {
}
