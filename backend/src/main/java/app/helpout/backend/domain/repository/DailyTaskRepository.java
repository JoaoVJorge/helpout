package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.DailyTask;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DailyTaskRepository extends JpaRepository<DailyTask, String> {

    List<DailyTask> findByUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    List<DailyTask> findByUserId(UUID userId);
}
