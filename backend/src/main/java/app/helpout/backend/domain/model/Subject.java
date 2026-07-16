package app.helpout.backend.domain.model;

import app.helpout.backend.domain.enums.TimeCategoryType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "subjects")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Subject {

    @Id
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 160)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private TimeCategoryType category;

    @Column(name = "color_value", nullable = false)
    private long colorValue;

    @Column(name = "total_seconds", nullable = false)
    private int totalSeconds;

    @Column(name = "goal_seconds", nullable = false)
    private int goalSeconds;

    @Column(name = "current_pages", nullable = false)
    private int currentPages;

    @Column(name = "goal_pages", nullable = false)
    private int goalPages;

    @Column(nullable = false)
    private String notes = "";

    @Column(name = "icon_name", nullable = false, length = 60)
    private String iconName = "";

    @Column(name = "rest_minutes", nullable = false)
    private int restMinutes = 5;

    @Column(name = "wallpaper_index", nullable = false)
    private int wallpaperIndex;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @Column(name = "deleted_at")
    private Instant deletedAt;

    public Subject(String id, User user) {
        this.id = id;
        this.user = user;
    }

    @PrePersist
    @PreUpdate
    void touch() {
        updatedAt = Instant.now();
    }
}
