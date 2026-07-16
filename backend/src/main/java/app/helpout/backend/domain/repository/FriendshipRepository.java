package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.Friendship;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FriendshipRepository extends JpaRepository<Friendship, UUID> {

    List<Friendship> findByUserId(UUID userId);

    boolean existsByUserIdAndFriendId(UUID userId, UUID friendId);
}
