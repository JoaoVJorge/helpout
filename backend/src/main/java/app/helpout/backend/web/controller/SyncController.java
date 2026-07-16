package app.helpout.backend.web.controller;

import app.helpout.backend.domain.service.SyncService;
import app.helpout.backend.web.dto.ApiResponse;
import app.helpout.backend.web.dto.SyncPullResponseDto;
import app.helpout.backend.web.dto.SyncPushRequestDto;
import java.time.Instant;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/sync")
public class SyncController {

    private final SyncService syncService;

    public SyncController(SyncService syncService) {
        this.syncService = syncService;
    }

    @GetMapping
    public ApiResponse<SyncPullResponseDto> pull(
            @AuthenticationPrincipal UUID userId, @RequestParam(required = false) String since) {
        Instant sinceInstant = since == null || since.isBlank() ? null : Instant.parse(since);
        return ApiResponse.ok(syncService.pull(userId, sinceInstant));
    }

    @PostMapping
    public ApiResponse<Void> push(@AuthenticationPrincipal UUID userId, @RequestBody SyncPushRequestDto request) {
        syncService.push(userId, request);
        return ApiResponse.ok(null, "Synced");
    }
}
