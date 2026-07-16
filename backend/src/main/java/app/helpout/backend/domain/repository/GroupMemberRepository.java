package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.GroupMember;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, UUID> {

    List<GroupMember> findByGroupId(UUID groupId);

    List<GroupMember> findByUserId(UUID userId);

    List<GroupMember> findByUserIdAndGroupIdIn(UUID userId, List<UUID> groupIds);
}
