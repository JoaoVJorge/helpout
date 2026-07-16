package app.helpout.backend.domain.service;

import app.helpout.backend.web.dto.SyncPullResponseDto;
import app.helpout.backend.web.dto.SyncPushRequestDto;
import java.time.Instant;
import java.util.UUID;

public interface SyncService {

    SyncPullResponseDto pull(UUID userId, Instant since);

    void push(UUID userId, SyncPushRequestDto request);
}
