package app.helpout.backend.configuration.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.security.jwt")
public record JwtProperties(String secret, int accessTokenTtlMinutes, int refreshTokenTtlDays) {
}
