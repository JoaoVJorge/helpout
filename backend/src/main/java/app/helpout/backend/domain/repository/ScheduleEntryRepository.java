package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.ScheduleEntry;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ScheduleEntryRepository extends JpaRepository<ScheduleEntry, String> {

    List<ScheduleEntry> findByUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    List<ScheduleEntry> findByUserId(UUID userId);
}
