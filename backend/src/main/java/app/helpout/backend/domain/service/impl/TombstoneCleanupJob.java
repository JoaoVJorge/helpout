package app.helpout.backend.domain.service.impl;

import app.helpout.backend.domain.repository.DailyTaskRepository;
import app.helpout.backend.domain.repository.OtpCodeRepository;
import app.helpout.backend.domain.repository.ScheduleEntryRepository;
import app.helpout.backend.domain.repository.SubjectRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Soft-deleted sync rows (and expired OTP codes) are kept around only long enough for other
 * devices to pick up the deletion on their next pull, then hard-deleted here.
 */
@Component
public class TombstoneCleanupJob {

    private final SubjectRepository subjectRepository;
    private final DailyTaskRepository dailyTaskRepository;
    private final ScheduleEntryRepository scheduleEntryRepository;
    private final OtpCodeRepository otpCodeRepository;
    private final int tombstoneRetentionDays;

    public TombstoneCleanupJob(
            SubjectRepository subjectRepository,
            DailyTaskRepository dailyTaskRepository,
            ScheduleEntryRepository scheduleEntryRepository,
            OtpCodeRepository otpCodeRepository,
            @Value("${app.tombstone-retention-days}") int tombstoneRetentionDays) {
        this.subjectRepository = subjectRepository;
        this.dailyTaskRepository = dailyTaskRepository;
        this.scheduleEntryRepository = scheduleEntryRepository;
        this.otpCodeRepository = otpCodeRepository;
        this.tombstoneRetentionDays = tombstoneRetentionDays;
    }

    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void purgeExpiredData() {
        Instant threshold = Instant.now().minus(tombstoneRetentionDays, ChronoUnit.DAYS);

        subjectRepository.findAll().stream()
                .filter(subject -> subject.getDeletedAt() != null && subject.getDeletedAt().isBefore(threshold))
                .forEach(subjectRepository::delete);
        dailyTaskRepository.findAll().stream()
                .filter(task -> task.getDeletedAt() != null && task.getDeletedAt().isBefore(threshold))
                .forEach(dailyTaskRepository::delete);
        scheduleEntryRepository.findAll().stream()
                .filter(entry -> entry.getDeletedAt() != null && entry.getDeletedAt().isBefore(threshold))
                .forEach(scheduleEntryRepository::delete);
        otpCodeRepository.deleteByExpiresAtBefore(Instant.now());
    }
}
