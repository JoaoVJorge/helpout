CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number            VARCHAR(32) NOT NULL UNIQUE,
    user_name               VARCHAR(120) NOT NULL DEFAULT '',
    nick_name               VARCHAR(60) NOT NULL DEFAULT '',
    email                   VARCHAR(160),
    birth_date              DATE,
    accent_color_value      BIGINT NOT NULL DEFAULT 4294951431,
    avatar_icon_index       INTEGER NOT NULL DEFAULT 0,
    notifications_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
    language_code           VARCHAR(8) NOT NULL DEFAULT 'en',
    is_dark_mode            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);

CREATE TABLE otp_codes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(32) NOT NULL,
    code_hash       VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    consumed        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_otp_codes_phone_number ON otp_codes (phone_number);

CREATE TABLE subjects (
    id                  VARCHAR(64) PRIMARY KEY,
    user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name                VARCHAR(160) NOT NULL,
    category            VARCHAR(32) NOT NULL,
    color_value         BIGINT NOT NULL,
    total_seconds       INTEGER NOT NULL DEFAULT 0,
    goal_seconds        INTEGER NOT NULL DEFAULT 0,
    current_pages       INTEGER NOT NULL DEFAULT 0,
    goal_pages          INTEGER NOT NULL DEFAULT 0,
    notes               TEXT NOT NULL DEFAULT '',
    icon_name           VARCHAR(60) NOT NULL DEFAULT '',
    rest_minutes        INTEGER NOT NULL DEFAULT 5,
    wallpaper_index     INTEGER NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at          TIMESTAMPTZ
);
CREATE INDEX idx_subjects_user_id ON subjects (user_id);
CREATE INDEX idx_subjects_updated_at ON subjects (updated_at);

CREATE TABLE daily_tasks (
    id              VARCHAR(64) PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name            VARCHAR(160) NOT NULL,
    color_value     BIGINT NOT NULL,
    target_days     INTEGER NOT NULL DEFAULT 1,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);
CREATE INDEX idx_daily_tasks_user_id ON daily_tasks (user_id);
CREATE INDEX idx_daily_tasks_updated_at ON daily_tasks (updated_at);

CREATE TABLE daily_task_completed_dates (
    daily_task_id   VARCHAR(64) NOT NULL REFERENCES daily_tasks (id) ON DELETE CASCADE,
    date_key        VARCHAR(10) NOT NULL,
    PRIMARY KEY (daily_task_id, date_key)
);

CREATE TABLE schedule_entries (
    id              VARCHAR(64) PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title           VARCHAR(160) NOT NULL,
    weekday         INTEGER NOT NULL,
    start_minutes   INTEGER NOT NULL,
    end_minutes     INTEGER,
    color_value     BIGINT NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);
CREATE INDEX idx_schedule_entries_user_id ON schedule_entries (user_id);
CREATE INDEX idx_schedule_entries_updated_at ON schedule_entries (updated_at);

CREATE TABLE friendships (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    friend_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, friend_id)
);

CREATE TABLE groups_table (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(160) NOT NULL,
    theme           VARCHAR(32) NOT NULL,
    owner_user_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    invite_code     VARCHAR(16) NOT NULL UNIQUE,
    privacy         VARCHAR(32) NOT NULL DEFAULT 'inviteOnly',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE group_members (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id            UUID NOT NULL REFERENCES groups_table (id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    display_name        VARCHAR(120) NOT NULL,
    avatar_color_value  BIGINT NOT NULL,
    role                VARCHAR(32) NOT NULL DEFAULT 'member',
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    today_seconds       INTEGER NOT NULL DEFAULT 0,
    week_seconds        INTEGER NOT NULL DEFAULT 0,
    month_seconds       INTEGER NOT NULL DEFAULT 0,
    UNIQUE (group_id, user_id)
);
CREATE INDEX idx_group_members_group_id ON group_members (group_id);
CREATE INDEX idx_group_members_user_id ON group_members (user_id);
