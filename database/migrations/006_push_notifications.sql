-- Push notification tokens
-- Migration: 006_push_notifications

-- Device tokens for push notifications
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token),
    CONSTRAINT valid_platform CHECK (platform IN ('ios', 'android', 'web'))
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

-- Notification preferences
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    new_activity BOOLEAN DEFAULT true,
    activity_reminder BOOLEAN DEFAULT true,
    activity_cancelled BOOLEAN DEFAULT true,
    new_fine BOOLEAN DEFAULT true,
    fine_decision BOOLEAN DEFAULT true,
    team_message BOOLEAN DEFAULT true,
    UNIQUE(user_id, team_id)
);

CREATE INDEX idx_notification_preferences_user ON notification_preferences(user_id);
