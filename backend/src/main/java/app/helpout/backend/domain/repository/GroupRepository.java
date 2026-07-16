package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.Group;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GroupRepository extends JpaRepository<Group, UUID> {

    Optional<Group> findByInviteCode(String inviteCode);

    boolean existsByInviteCode(String inviteCode);
}
