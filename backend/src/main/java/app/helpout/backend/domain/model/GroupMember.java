package app.helpout.backend.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "group_members")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class GroupMember {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "display_name", nullable = false, length = 120)
    private String displayName;

    @Column(name = "avatar_color_value", nullable = false)
    private long avatarColorValue;

    @Column(nullable = false, length = 32)
    private String role = "member";

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt = Instant.now();

    @Column(name = "today_seconds", nullable = false)
    private int todaySeconds;

    @Column(name = "week_seconds", nullable = false)
    private int weekSeconds;

    @Column(name = "month_seconds", nullable = false)
    private int monthSeconds;

    public GroupMember(Group group, User user, String displayName, long avatarColorValue, String role) {
        this.group = group;
        this.user = user;
        this.displayName = displayName;
        this.avatarColorValue = avatarColorValue;
        this.role = role;
    }
}
