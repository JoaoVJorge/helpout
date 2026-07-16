package app.helpout.backend.domain.service.impl;

import app.helpout.backend.configuration.security.JwtService;
import app.helpout.backend.domain.exception.InvalidCredentialsException;
import app.helpout.backend.domain.model.OtpCode;
import app.helpout.backend.domain.model.RefreshToken;
import app.helpout.backend.domain.model.User;
import app.helpout.backend.domain.repository.OtpCodeRepository;
import app.helpout.backend.domain.repository.RefreshTokenRepository;
import app.helpout.backend.domain.repository.UserRepository;
import app.helpout.backend.domain.service.AuthService;
import app.helpout.backend.web.dto.AuthTokenResponseDto;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
public class AuthServiceImpl implements AuthService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final OtpCodeRepository otpCodeRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final int otpLength;
    private final int otpTtlMinutes;

    public AuthServiceImpl(
            UserRepository userRepository,
            OtpCodeRepository otpCodeRepository,
            RefreshTokenRepository refreshTokenRepository,
            JwtService jwtService,
            @Value("${app.otp.length}") int otpLength,
            @Value("${app.otp.ttl-minutes}") int otpTtlMinutes) {
        this.userRepository = userRepository;
        this.otpCodeRepository = otpCodeRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtService = jwtService;
        this.otpLength = otpLength;
        this.otpTtlMinutes = otpTtlMinutes;
    }

    @Override
    @Transactional
    public void requestOtp(String phoneNumber) {
        String code = generateNumericCode(otpLength);
        OtpCode otpCode = new OtpCode(phoneNumber, hash(code), Instant.now().plus(otpTtlMinutes, ChronoUnit.MINUTES));
        otpCodeRepository.save(otpCode);
        // No SMS provider configured yet (matches the client's mock docstring) — log for local/dev testing.
        log.info("OTP for {}: {}", phoneNumber, code);
    }

    @Override
    @Transactional
    public AuthTokenResponseDto verifyOtp(String phoneNumber, String code) {
        String codeHash = hash(code);
        boolean matches = otpCodeRepository.findByPhoneNumberAndConsumedFalseOrderByCreatedAtDesc(phoneNumber).stream()
                .filter(OtpCode::isValid)
                .anyMatch(otp -> {
                    boolean isMatch = otp.getCodeHash().equals(codeHash);
                    if (isMatch) {
                        otp.setConsumed(true);
                    }
                    return isMatch;
                });

        if (!matches) {
            throw new InvalidCredentialsException("Invalid or expired code");
        }

        User user = userRepository.findByPhoneNumber(phoneNumber).orElseGet(() -> userRepository.save(new User(phoneNumber)));

        return issueTokens(user);
    }

    @Override
    @Transactional
    public AuthTokenResponseDto refresh(String refreshToken) {
        String tokenHash = hash(refreshToken);
        RefreshToken existing = refreshTokenRepository
                .findByTokenHash(tokenHash)
                .orElseThrow(() -> new InvalidCredentialsException("Invalid refresh token"));

        if (existing.isExpired()) {
            refreshTokenRepository.delete(existing);
            throw new InvalidCredentialsException("Refresh token expired");
        }

        User user = existing.getUser();
        refreshTokenRepository.delete(existing);
        return issueTokens(user);
    }

    private AuthTokenResponseDto issueTokens(User user) {
        String accessToken = jwtService.generateAccessToken(user.getId());
        String refreshToken = generateOpaqueToken();
        RefreshToken refreshTokenEntity = new RefreshToken(
                user, hash(refreshToken), Instant.now().plus(jwtService.refreshTokenTtlDays(), ChronoUnit.DAYS));
        refreshTokenRepository.save(refreshTokenEntity);

        return new AuthTokenResponseDto(accessToken, refreshToken, user.hasProfile());
    }

    private static String generateNumericCode(int length) {
        StringBuilder builder = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            builder.append(RANDOM.nextInt(10));
        }
        return builder.toString();
    }

    private static String generateOpaqueToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(value.getBytes());
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }
}
