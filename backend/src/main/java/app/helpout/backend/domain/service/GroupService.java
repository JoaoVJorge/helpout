package app.helpout.backend.domain.service;

import app.helpout.backend.web.dto.CreateGroupRequestDto;
import app.helpout.backend.web.dto.GroupDto;
import java.util.List;
import java.util.UUID;

public interface GroupService {

    List<GroupDto> listGroups(UUID userId);

    GroupDto createGroup(UUID userId, CreateGroupRequestDto request);
}
