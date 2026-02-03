-- Stopwatch and Timer System
-- Migration: 017_stopwatch
-- Tasks: DB-051 to DB-056

-- ============================================
-- STOPWATCH SESSIONS (DB-051 to DB-053)
-- ============================================

-- DB-051: Create stopwatch_sessions table
CREATE TABLE stopwatch_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID REFERENCES mini_activities(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(255),
    session_type VARCHAR(50) NOT NULL,
    countdown_duration_ms BIGINT,
    status VARCHAR(50) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE,
    paused_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    elapsed_ms_at_pause BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT session_has_context CHECK (mini_activity_id IS NOT NULL OR team_id IS NOT NULL)
);

COMMENT ON TABLE stopwatch_sessions IS 'Stopwatch or countdown timer sessions for activities';

-- DB-052: Add session_type constraint
ALTER TABLE stopwatch_sessions
    ADD CONSTRAINT valid_session_type
    CHECK (session_type IN ('stopwatch', 'countdown'));

-- DB-053: Add status constraint
ALTER TABLE stopwatch_sessions
    ADD CONSTRAINT valid_session_status
    CHECK (status IN ('pending', 'running', 'paused', 'completed', 'cancelled'));

CREATE INDEX idx_stopwatch_mini ON stopwatch_sessions(mini_activity_id) WHERE mini_activity_id IS NOT NULL;
CREATE INDEX idx_stopwatch_team ON stopwatch_sessions(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_stopwatch_status ON stopwatch_sessions(status);
CREATE INDEX idx_stopwatch_created_by ON stopwatch_sessions(created_by);

-- ============================================
-- STOPWATCH TIMES (DB-054 to DB-056)
-- ============================================

-- DB-054: Create stopwatch_times table
CREATE TABLE stopwatch_times (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES stopwatch_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    time_ms BIGINT NOT NULL,
    is_split BOOLEAN DEFAULT FALSE,
    split_number INTEGER,
    lap_number INTEGER,
    notes TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE stopwatch_times IS 'Individual time recordings within a stopwatch session';

-- DB-055: Add unique constraint for splits
ALTER TABLE stopwatch_times
    ADD CONSTRAINT unique_user_split
    UNIQUE(session_id, user_id, split_number)
    DEFERRABLE INITIALLY DEFERRED;

-- DB-056: Add indexes to stopwatch_times
CREATE INDEX idx_times_session ON stopwatch_times(session_id);
CREATE INDEX idx_times_user ON stopwatch_times(user_id);
CREATE INDEX idx_times_time ON stopwatch_times(time_ms);
CREATE INDEX idx_times_recorded ON stopwatch_times(recorded_at DESC);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to format milliseconds as time string
CREATE OR REPLACE FUNCTION format_time_ms(ms BIGINT)
RETURNS TEXT AS $$
DECLARE
    hours INTEGER;
    minutes INTEGER;
    seconds INTEGER;
    milliseconds INTEGER;
BEGIN
    hours := ms / 3600000;
    minutes := (ms % 3600000) / 60000;
    seconds := (ms % 60000) / 1000;
    milliseconds := ms % 1000;

    IF hours > 0 THEN
        RETURN LPAD(hours::TEXT, 2, '0') || ':' ||
               LPAD(minutes::TEXT, 2, '0') || ':' ||
               LPAD(seconds::TEXT, 2, '0') || '.' ||
               LPAD(milliseconds::TEXT, 3, '0');
    ELSE
        RETURN LPAD(minutes::TEXT, 2, '0') || ':' ||
               LPAD(seconds::TEXT, 2, '0') || '.' ||
               LPAD(milliseconds::TEXT, 3, '0');
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_time_ms IS 'Formats milliseconds as MM:SS.mmm or HH:MM:SS.mmm';

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN stopwatch_sessions.session_type IS 'stopwatch = count up, countdown = count down from duration';
COMMENT ON COLUMN stopwatch_sessions.countdown_duration_ms IS 'Duration in milliseconds for countdown timers';
COMMENT ON COLUMN stopwatch_sessions.status IS 'pending, running, paused, completed, cancelled';
COMMENT ON COLUMN stopwatch_sessions.elapsed_ms_at_pause IS 'Elapsed time when paused (for resume calculation)';
COMMENT ON COLUMN stopwatch_times.time_ms IS 'Recorded time in milliseconds';
COMMENT ON COLUMN stopwatch_times.is_split IS 'Whether this is a split/lap time vs final time';
COMMENT ON COLUMN stopwatch_times.split_number IS 'Split number for multi-split recordings';
COMMENT ON COLUMN stopwatch_times.lap_number IS 'Lap number for lap-based recordings';
