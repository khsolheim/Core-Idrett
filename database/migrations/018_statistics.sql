-- Mini-Activity Statistics
-- Migration: 018_statistics
-- Tasks: DB-057 to DB-066

-- ============================================
-- PLAYER STATISTICS (DB-057 to DB-059)
-- ============================================

-- DB-057: Create mini_activity_player_stats table
CREATE TABLE mini_activity_player_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE CASCADE,
    total_participations INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_draws INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    first_place_count INTEGER DEFAULT 0,
    second_place_count INTEGER DEFAULT 0,
    third_place_count INTEGER DEFAULT 0,
    best_streak INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    average_placement DECIMAL(5,2),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE mini_activity_player_stats IS 'Aggregated statistics for players in mini-activities';

-- DB-058: Add unique constraint
ALTER TABLE mini_activity_player_stats
    ADD CONSTRAINT unique_player_stats
    UNIQUE(user_id, team_id, season_id);

-- DB-059: Add indexes
CREATE INDEX idx_player_stats_user ON mini_activity_player_stats(user_id);
CREATE INDEX idx_player_stats_team ON mini_activity_player_stats(team_id);
CREATE INDEX idx_player_stats_season ON mini_activity_player_stats(season_id) WHERE season_id IS NOT NULL;
CREATE INDEX idx_player_stats_wins ON mini_activity_player_stats(team_id, total_wins DESC);
CREATE INDEX idx_player_stats_points ON mini_activity_player_stats(team_id, total_points DESC);

-- ============================================
-- HEAD-TO-HEAD STATISTICS (DB-060 to DB-062)
-- ============================================

-- DB-060: Create mini_activity_head_to_head table
CREATE TABLE mini_activity_head_to_head (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user1_wins INTEGER DEFAULT 0,
    user2_wins INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    total_matchups INTEGER DEFAULT 0,
    last_matchup_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE mini_activity_head_to_head IS 'Head-to-head records between players';

-- DB-061: Add constraint for consistent ordering
ALTER TABLE mini_activity_head_to_head
    ADD CONSTRAINT ordered_users
    CHECK (user1_id < user2_id);

-- DB-062: Add unique constraint
ALTER TABLE mini_activity_head_to_head
    ADD CONSTRAINT unique_head_to_head
    UNIQUE(team_id, user1_id, user2_id);

CREATE INDEX idx_h2h_team ON mini_activity_head_to_head(team_id);
CREATE INDEX idx_h2h_user1 ON mini_activity_head_to_head(user1_id);
CREATE INDEX idx_h2h_user2 ON mini_activity_head_to_head(user2_id);

-- ============================================
-- TEAM HISTORY (DB-063 to DB-064)
-- ============================================

-- DB-063: Create mini_activity_team_history table
CREATE TABLE mini_activity_team_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    mini_team_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    team_name VARCHAR(100),
    teammates JSONB,
    placement INTEGER,
    points_earned INTEGER DEFAULT 0,
    was_winner BOOLEAN DEFAULT FALSE,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE mini_activity_team_history IS 'Historical record of which teams players were on';

-- DB-064: Add unique constraint
ALTER TABLE mini_activity_team_history
    ADD CONSTRAINT unique_team_history
    UNIQUE(user_id, mini_activity_id);

CREATE INDEX idx_team_history_user ON mini_activity_team_history(user_id);
CREATE INDEX idx_team_history_mini ON mini_activity_team_history(mini_activity_id);
CREATE INDEX idx_team_history_date ON mini_activity_team_history(recorded_at DESC);

-- ============================================
-- LEADERBOARD POINT SOURCES (DB-065 to DB-066)
-- ============================================

-- DB-065: Create leaderboard_point_sources table
CREATE TABLE leaderboard_point_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leaderboard_entry_id UUID NOT NULL REFERENCES leaderboard_entries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type VARCHAR(50) NOT NULL,
    source_id UUID NOT NULL,
    points INTEGER NOT NULL,
    description TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE leaderboard_point_sources IS 'Tracks where leaderboard points came from';

-- Add source_type constraint
ALTER TABLE leaderboard_point_sources
    ADD CONSTRAINT valid_source_type
    CHECK (source_type IN (
        'mini_activity',
        'tournament',
        'attendance',
        'test_result',
        'manual_adjustment',
        'bonus',
        'penalty'
    ));

-- DB-066: Add indexes
CREATE INDEX idx_point_sources_entry ON leaderboard_point_sources(leaderboard_entry_id);
CREATE INDEX idx_point_sources_user ON leaderboard_point_sources(user_id);
CREATE INDEX idx_point_sources_type ON leaderboard_point_sources(source_type);
CREATE INDEX idx_point_sources_source ON leaderboard_point_sources(source_type, source_id);
CREATE INDEX idx_point_sources_date ON leaderboard_point_sources(recorded_at DESC);

-- ============================================
-- HELPER VIEWS
-- ============================================

-- View for player win rates
CREATE OR REPLACE VIEW v_player_win_rates AS
SELECT
    ps.user_id,
    ps.team_id,
    ps.season_id,
    ps.total_participations,
    ps.total_wins,
    ps.total_losses,
    ps.total_draws,
    CASE
        WHEN ps.total_participations > 0
        THEN ROUND((ps.total_wins::DECIMAL / ps.total_participations) * 100, 2)
        ELSE 0
    END AS win_rate_percent,
    u.name AS user_name,
    t.name AS team_name
FROM mini_activity_player_stats ps
JOIN users u ON u.id = ps.user_id
JOIN teams t ON t.id = ps.team_id;

COMMENT ON VIEW v_player_win_rates IS 'Player statistics with calculated win rates';

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN mini_activity_player_stats.best_streak IS 'Longest winning streak ever';
COMMENT ON COLUMN mini_activity_player_stats.current_streak IS 'Current winning streak (negative for losing streak)';
COMMENT ON COLUMN mini_activity_player_stats.average_placement IS 'Average placement across all activities';
COMMENT ON COLUMN mini_activity_head_to_head.user1_id IS 'Always the smaller UUID (for consistent ordering)';
COMMENT ON COLUMN mini_activity_head_to_head.user2_id IS 'Always the larger UUID (for consistent ordering)';
COMMENT ON COLUMN mini_activity_team_history.teammates IS 'JSONB array of teammate user IDs and names';
COMMENT ON COLUMN leaderboard_point_sources.source_type IS 'Type of activity that generated the points';
COMMENT ON COLUMN leaderboard_point_sources.source_id IS 'ID of the source (mini_activity_id, tournament_id, etc.)';
