package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.Subject;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, String> {

    List<Subject> findByUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    List<Subject> findByUserId(UUID userId);
}
