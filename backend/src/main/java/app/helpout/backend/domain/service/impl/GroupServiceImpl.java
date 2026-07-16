package app.helpout.backend.domain.service.impl;

import app.helpout.backend.domain.exception.NotFoundException;
import app.helpout.backend.domain.model.Group;
import app.helpout.backend.domain.model.GroupMember;
import app.helpout.backend.domain.model.User;
import app.helpout.backend.domain.repository.GroupMemberRepository;
import app.helpout.backend.domain.repository.GroupRepository;
import app.helpout.backend.domain.repository.UserRepository;
import app.helpout.backend.domain.service.GroupService;
import app.helpout.backend.web.dto.CreateGroupRequestDto;
import app.helpout.backend.web.dto.GroupDto;
import app.helpout.backend.web.dto.GroupMemberDto;
import java.security.SecureRandom;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GroupServiceImpl implements GroupService {

    private static final String INVITE_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    public GroupServiceImpl(
            GroupRepository groupRepository, GroupMemberRepository groupMemberRepository, UserRepository userRepository) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupDto> listGroups(UUID userId) {
        return groupMemberRepository.findByUserId(userId).stream()
                .map(GroupMember::getGroup)
                .distinct()
                .map(this::toDto)
                .toList();
    }

    @Override
    @Transactional
    public GroupDto createGroup(UUID userId, CreateGroupRequestDto request) {
        User owner = userRepository.findById(userId).orElseThrow(() -> new NotFoundException("User not found"));

        Group group = new Group(request.name(), request.theme(), owner, generateInviteCode());
        groupRepository.save(group);

        groupMemberRepository.save(new GroupMember(group, owner, ownerDisplayName(owner), 0xFFFFC107L, "owner"));

        for (String memberId : request.memberIds()) {
            User member = userRepository
                    .findById(UUID.fromString(memberId))
                    .orElseThrow(() -> new NotFoundException("User not found: " + memberId));
            groupMemberRepository.save(new GroupMember(group, member, ownerDisplayName(member), 0xFFFFFFFFL, "member"));
        }

        return toDto(group);
    }

    private GroupDto toDto(Group group) {
        List<GroupMemberDto> members = groupMemberRepository.findByGroupId(group.getId()).stream()
                .map(member -> new GroupMemberDto(
                        member.getUser().getId().toString(),
                        member.getDisplayName(),
                        member.getAvatarColorValue(),
                        member.getTodaySeconds(),
                        member.getWeekSeconds(),
                        member.getMonthSeconds(),
                        member.getRole()))
                .toList();

        return new GroupDto(
                group.getId().toString(),
                group.getName(),
                group.getTheme(),
                members,
                group.getOwner().getId().toString(),
                group.getCreatedAt().toString(),
                group.getInviteCode(),
                group.getPrivacy());
    }

    private static String ownerDisplayName(User user) {
        return user.getNickName() != null && !user.getNickName().isBlank() ? user.getNickName() : user.getUserName();
    }

    private String generateInviteCode() {
        String code;
        do {
            StringBuilder builder = new StringBuilder(6);
            for (int i = 0; i < 6; i++) {
                builder.append(INVITE_CODE_ALPHABET.charAt(RANDOM.nextInt(INVITE_CODE_ALPHABET.length())));
            }
            code = builder.toString();
        } while (groupRepository.existsByInviteCode(code));
        return code;
    }
}
