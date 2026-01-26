-- Statistics and ratings
-- Migration: 004_statistics

-- Match statistics
CREATE TABLE match_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES activity_instances(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goals INTEGER DEFAULT 0,
    assists INTEGER DEFAULT 0,
    minutes_played INTEGER DEFAULT 0,
    yellow_cards INTEGER DEFAULT 0,
    red_cards INTEGER DEFAULT 0,
    UNIQUE(instance_id, user_id)
);

CREATE INDEX idx_match_stats_instance ON match_stats(instance_id);
CREATE INDEX idx_match_stats_user ON match_stats(user_id);

-- Player ratings (ELO-like)
CREATE TABLE player_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    rating DECIMAL(7,2) DEFAULT 1000.00,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, team_id)
);

CREATE INDEX idx_player_ratings_team ON player_ratings(team_id);
CREATE INDEX idx_player_ratings_user ON player_ratings(user_id);
CREATE INDEX idx_player_ratings_rating ON player_ratings(rating DESC);

-- Season statistics aggregate
CREATE TABLE season_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_year INTEGER NOT NULL,
    attendance_count INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    total_goals INTEGER DEFAULT 0,
    total_assists INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_draws INTEGER DEFAULT 0,
    UNIQUE(user_id, team_id, season_year)
);

CREATE INDEX idx_season_stats_team_year ON season_stats(team_id, season_year);
