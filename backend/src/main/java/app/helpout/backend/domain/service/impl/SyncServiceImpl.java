package app.helpout.backend.domain.service.impl;

import app.helpout.backend.domain.enums.TimeCategoryType;
import app.helpout.backend.domain.exception.NotFoundException;
import app.helpout.backend.domain.model.DailyTask;
import app.helpout.backend.domain.model.Group;
import app.helpout.backend.domain.model.GroupMember;
import app.helpout.backend.domain.model.ScheduleEntry;
import app.helpout.backend.domain.model.Subject;
import app.helpout.backend.domain.model.User;
import app.helpout.backend.domain.repository.DailyTaskRepository;
import app.helpout.backend.domain.repository.GroupMemberRepository;
import app.helpout.backend.domain.repository.GroupRepository;
import app.helpout.backend.domain.repository.ScheduleEntryRepository;
import app.helpout.backend.domain.repository.SubjectRepository;
import app.helpout.backend.domain.repository.UserRepository;
import app.helpout.backend.domain.service.SyncService;
import app.helpout.backend.web.dto.DailyTaskDto;
import app.helpout.backend.web.dto.GroupContributionDto;
import app.helpout.backend.web.dto.GroupDto;
import app.helpout.backend.web.dto.GroupMemberDto;
import app.helpout.backend.web.dto.ScheduleEntryDto;
import app.helpout.backend.web.dto.SubjectDto;
import app.helpout.backend.web.dto.SyncPullResponseDto;
import app.helpout.backend.web.dto.SyncPushRequestDto;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SyncServiceImpl implements SyncService {

    private final UserRepository userRepository;
    private final SubjectRepository subjectRepository;
    private final DailyTaskRepository dailyTaskRepository;
    private final ScheduleEntryRepository scheduleEntryRepository;
    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;

    public SyncServiceImpl(
            UserRepository userRepository,
            SubjectRepository subjectRepository,
            DailyTaskRepository dailyTaskRepository,
            ScheduleEntryRepository scheduleEntryRepository,
            GroupRepository groupRepository,
            GroupMemberRepository groupMemberRepository) {
        this.userRepository = userRepository;
        this.subjectRepository = subjectRepository;
        this.dailyTaskRepository = dailyTaskRepository;
        this.scheduleEntryRepository = scheduleEntryRepository;
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public SyncPullResponseDto pull(UUID userId, Instant since) {
        List<Subject> subjects = since == null
                ? subjectRepository.findByUserId(userId)
                : subjectRepository.findByUserIdAndUpdatedAtAfter(userId, since);
        List<DailyTask> dailyTasks = since == null
                ? dailyTaskRepository.findByUserId(userId)
                : dailyTaskRepository.findByUserIdAndUpdatedAtAfter(userId, since);
        List<ScheduleEntry> scheduleEntries = since == null
                ? scheduleEntryRepository.findByUserId(userId)
                : scheduleEntryRepository.findByUserIdAndUpdatedAtAfter(userId, since);

        return new SyncPullResponseDto(
                subjects.stream().map(SyncServiceImpl::toDto).toList(),
                dailyTasks.stream().map(SyncServiceImpl::toDto).toList(),
                scheduleEntries.stream().map(SyncServiceImpl::toDto).toList(),
                loadGroups(userId),
                Instant.now().toString());
    }

    @Override
    @Transactional
    public void push(UUID userId, SyncPushRequestDto request) {
        User user = userRepository.findById(userId).orElseThrow(() -> new NotFoundException("User not found"));

        if (request.subjects() != null) {
            request.subjects().forEach(dto -> applySubject(user, dto));
        }
        if (request.dailyTasks() != null) {
            request.dailyTasks().forEach(dto -> applyDailyTask(user, dto));
        }
        if (request.scheduleEntries() != null) {
            request.scheduleEntries().forEach(dto -> applyScheduleEntry(user, dto));
        }
        if (request.groupContributions() != null) {
            request.groupContributions().forEach(dto -> applyGroupContribution(userId, dto));
        }
    }

    private void applySubject(User user, SubjectDto dto) {
        Subject subject = subjectRepository.findById(dto.id())
                .filter(existing -> existing.getUser().getId().equals(user.getId()))
                .orElseGet(() -> new Subject(dto.id(), user));

        if (dto.deleted()) {
            subject.setDeletedAt(Instant.now());
            subjectRepository.save(subject);
            return;
        }

        subject.setName(dto.name());
        subject.setCategory(TimeCategoryType.valueOf(dto.category()));
        subject.setColorValue(dto.colorValue());
        subject.setTotalSeconds(dto.totalSeconds());
        subject.setGoalSeconds(dto.goalSeconds());
        subject.setCurrentPages(dto.currentPages());
        subject.setGoalPages(dto.goalPages());
        subject.setNotes(dto.notes());
        subject.setIconName(dto.iconName());
        subject.setRestMinutes(dto.restMinutes());
        subject.setWallpaperIndex(dto.wallpaperIndex());
        subject.setDeletedAt(null);
        subjectRepository.save(subject);
    }

    private void applyDailyTask(User user, DailyTaskDto dto) {
        DailyTask dailyTask = dailyTaskRepository.findById(dto.id())
                .filter(existing -> existing.getUser().getId().equals(user.getId()))
                .orElseGet(() -> new DailyTask(dto.id(), user));

        if (dto.deleted()) {
            dailyTask.setDeletedAt(Instant.now());
            dailyTaskRepository.save(dailyTask);
            return;
        }

        dailyTask.setName(dto.name());
        dailyTask.setColorValue(dto.colorValue());
        dailyTask.setTargetDays(dto.targetDays());
        dailyTask.getCompletedDates().clear();
        if (dto.completedDates() != null) {
            dailyTask.getCompletedDates().addAll(dto.completedDates());
        }
        dailyTask.setDeletedAt(null);
        dailyTaskRepository.save(dailyTask);
    }

    private void applyScheduleEntry(User user, ScheduleEntryDto dto) {
        ScheduleEntry entry = scheduleEntryRepository.findById(dto.id())
                .filter(existing -> existing.getUser().getId().equals(user.getId()))
                .orElseGet(() -> new ScheduleEntry(dto.id(), user));

        if (dto.deleted()) {
            entry.setDeletedAt(Instant.now());
            scheduleEntryRepository.save(entry);
            return;
        }

        entry.setTitle(dto.title());
        entry.setWeekday(dto.weekday());
        entry.setStartMinutes(dto.startMinutes());
        entry.setEndMinutes(dto.endMinutes());
        entry.setColorValue(dto.colorValue());
        entry.setDeletedAt(null);
        scheduleEntryRepository.save(entry);
    }

    private void applyGroupContribution(UUID userId, GroupContributionDto dto) {
        UUID groupId = UUID.fromString(dto.groupId());
        groupMemberRepository.findByGroupId(groupId).stream()
                .filter(member -> member.getUser().getId().equals(userId))
                .findFirst()
                .ifPresent(member -> {
                    member.setTodaySeconds(dto.todaySeconds());
                    member.setWeekSeconds(dto.weekSeconds());
                    member.setMonthSeconds(dto.monthSeconds());
                    groupMemberRepository.save(member);
                });
    }

    private List<GroupDto> loadGroups(UUID userId) {
        List<GroupMember> memberships = groupMemberRepository.findByUserId(userId);
        return memberships.stream()
                .map(GroupMember::getGroup)
                .distinct()
                .map(this::toGroupDto)
                .toList();
    }

    private GroupDto toGroupDto(Group group) {
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

    private static SubjectDto toDto(Subject subject) {
        return new SubjectDto(
                subject.getId(),
                subject.getName(),
                subject.getCategory().name(),
                subject.getColorValue(),
                subject.getTotalSeconds(),
                subject.getGoalSeconds(),
                subject.getCurrentPages(),
                subject.getGoalPages(),
                subject.getNotes(),
                subject.getIconName(),
                subject.getRestMinutes(),
                subject.getWallpaperIndex(),
                subject.getDeletedAt() != null);
    }

    private static DailyTaskDto toDto(DailyTask dailyTask) {
        return new DailyTaskDto(
                dailyTask.getId(),
                dailyTask.getName(),
                dailyTask.getColorValue(),
                dailyTask.getTargetDays(),
                dailyTask.getCompletedDates().stream().sorted().toList(),
                dailyTask.getDeletedAt() != null);
    }

    private static ScheduleEntryDto toDto(ScheduleEntry entry) {
        return new ScheduleEntryDto(
                entry.getId(),
                entry.getTitle(),
                entry.getWeekday(),
                entry.getStartMinutes(),
                entry.getEndMinutes(),
                entry.getColorValue(),
                entry.getDeletedAt() != null);
    }
}
