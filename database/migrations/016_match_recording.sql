-- Match Recording: Periods and Events
-- Migration: 016_match_recording
-- Tasks: DB-047 to DB-050

-- ============================================
-- MATCH PERIODS (DB-047)
-- ============================================

-- DB-047: Create match_periods table
CREATE TABLE match_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_match_id UUID REFERENCES tournament_matches(id) ON DELETE CASCADE,
    group_match_id UUID REFERENCES group_matches(id) ON DELETE CASCADE,
    mini_activity_id UUID REFERENCES mini_activities(id) ON DELETE CASCADE,
    period_number INTEGER NOT NULL DEFAULT 1,
    period_name VARCHAR(50),
    team_a_score INTEGER DEFAULT 0,
    team_b_score INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT period_has_match CHECK (
        tournament_match_id IS NOT NULL OR
        group_match_id IS NOT NULL OR
        mini_activity_id IS NOT NULL
    )
);

COMMENT ON TABLE match_periods IS 'Periods/halves within matches for detailed scoring';

CREATE INDEX idx_periods_tournament_match ON match_periods(tournament_match_id) WHERE tournament_match_id IS NOT NULL;
CREATE INDEX idx_periods_group_match ON match_periods(group_match_id) WHERE group_match_id IS NOT NULL;
CREATE INDEX idx_periods_mini ON match_periods(mini_activity_id) WHERE mini_activity_id IS NOT NULL;

-- ============================================
-- MATCH EVENTS (DB-048 to DB-050)
-- ============================================

-- DB-048: Create match_events table
CREATE TABLE match_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_period_id UUID NOT NULL REFERENCES match_periods(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    team_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    minute INTEGER,
    second INTEGER,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DB-049: Add event_type constraint
ALTER TABLE match_events
    ADD CONSTRAINT valid_event_type
    CHECK (event_type IN (
        'goal',
        'own_goal',
        'penalty_scored',
        'penalty_missed',
        'yellow_card',
        'red_card',
        'substitution',
        'injury',
        'timeout',
        'period_start',
        'period_end',
        'custom'
    ));

COMMENT ON TABLE match_events IS 'Individual events during a match period (goals, cards, etc.)';

-- DB-050: Add indexes to match_events
CREATE INDEX idx_events_period ON match_events(match_period_id);
CREATE INDEX idx_events_team ON match_events(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_events_user ON match_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_events_type ON match_events(event_type);
CREATE INDEX idx_events_time ON match_events(match_period_id, minute, second);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN match_periods.period_number IS 'Period number (1 = first half, 2 = second half, etc.)';
COMMENT ON COLUMN match_periods.period_name IS 'Optional name (e.g., "1. omgang", "Overtid")';
COMMENT ON COLUMN match_events.event_type IS 'Type of event: goal, own_goal, penalty_scored, penalty_missed, yellow_card, red_card, etc.';
COMMENT ON COLUMN match_events.minute IS 'Minute when event occurred';
COMMENT ON COLUMN match_events.second IS 'Second within the minute (optional precision)';
COMMENT ON COLUMN match_events.metadata IS 'Additional event-specific data as JSON';
