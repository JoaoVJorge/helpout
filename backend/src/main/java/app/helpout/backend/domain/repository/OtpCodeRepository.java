package app.helpout.backend.domain.repository;

import app.helpout.backend.domain.model.OtpCode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OtpCodeRepository extends JpaRepository<OtpCode, UUID> {

    List<OtpCode> findByPhoneNumberAndConsumedFalseOrderByCreatedAtDesc(String phoneNumber);

    void deleteByExpiresAtBefore(Instant threshold);
}
