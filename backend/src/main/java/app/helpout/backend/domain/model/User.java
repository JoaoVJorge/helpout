package app.helpout.backend.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "phone_number", nullable = false, unique = true, length = 32)
    private String phoneNumber;

    @Column(name = "user_name", nullable = false, length = 120)
    private String userName = "";

    @Column(name = "nick_name", nullable = false, length = 60)
    private String nickName = "";

    @Column(length = 160)
    private String email;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "accent_color_value", nullable = false)
    private long accentColorValue = 0xFFFFC107L;

    @Column(name = "avatar_icon_index", nullable = false)
    private int avatarIconIndex;

    @Column(name = "notifications_enabled", nullable = false)
    private boolean notificationsEnabled = true;

    @Column(name = "language_code", nullable = false, length = 8)
    private String languageCode = "en";

    @Column(name = "is_dark_mode", nullable = false)
    private boolean darkMode;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public User(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public boolean hasProfile() {
        return userName != null && !userName.isBlank();
    }
}
