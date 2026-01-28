-- Tournament System
-- Migration: 015_tournament_system
-- Tasks: DB-027 to DB-046

-- ============================================
-- CORE TOURNAMENT TABLE (DB-027 to DB-030)
-- ============================================

-- DB-027: Create tournaments table
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    tournament_type VARCHAR(50) NOT NULL,
    best_of INTEGER DEFAULT 1,
    bronze_final BOOLEAN DEFAULT FALSE,
    seeding_method VARCHAR(50) DEFAULT 'random',
    max_participants INTEGER,
    status VARCHAR(50) DEFAULT 'setup',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DB-028: Add tournament_type constraint
ALTER TABLE tournaments
    ADD CONSTRAINT valid_tournament_type
    CHECK (tournament_type IN ('single_elimination', 'double_elimination', 'group_play', 'group_knockout'));

-- DB-029: Add best_of constraint
ALTER TABLE tournaments
    ADD CONSTRAINT valid_best_of
    CHECK (best_of IN (1, 3, 5, 7));

-- Add seeding_method constraint
ALTER TABLE tournaments
    ADD CONSTRAINT valid_seeding_method
    CHECK (seeding_method IN ('random', 'ranked', 'manual'));

-- Add status constraint
ALTER TABLE tournaments
    ADD CONSTRAINT valid_tournament_status
    CHECK (status IN ('setup', 'in_progress', 'completed', 'cancelled'));

-- DB-030: Add index on mini_activity_id
CREATE INDEX idx_tournaments_mini ON tournaments(mini_activity_id);

-- ============================================
-- TOURNAMENT ROUNDS (DB-031 to DB-033)
-- ============================================

-- DB-031: Create tournament_rounds table
CREATE TABLE tournament_rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    round_name VARCHAR(100),
    round_type VARCHAR(50) DEFAULT 'winners',
    status VARCHAR(50) DEFAULT 'pending',
    scheduled_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DB-032: Add round_type constraint
ALTER TABLE tournament_rounds
    ADD CONSTRAINT valid_round_type
    CHECK (round_type IN ('winners', 'losers', 'bronze', 'final'));

-- Add status constraint
ALTER TABLE tournament_rounds
    ADD CONSTRAINT valid_round_status
    CHECK (status IN ('pending', 'in_progress', 'completed'));

-- DB-033: Add unique constraint for round identification
ALTER TABLE tournament_rounds
    ADD CONSTRAINT unique_round
    UNIQUE(tournament_id, round_number, round_type);

CREATE INDEX idx_rounds_tournament ON tournament_rounds(tournament_id);

-- ============================================
-- TOURNAMENT MATCHES (DB-034 to DB-040)
-- ============================================

-- DB-034: Create tournament_matches table
CREATE TABLE tournament_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    round_id UUID NOT NULL REFERENCES tournament_rounds(id) ON DELETE CASCADE,
    bracket_position INTEGER NOT NULL,
    team_a_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    team_b_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    team_a_score INTEGER,
    team_b_score INTEGER,
    status VARCHAR(50) DEFAULT 'pending',
    scheduled_time TIMESTAMP WITH TIME ZONE,
    match_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DB-035: Add winner_goes_to_match_id for bracket progression
ALTER TABLE tournament_matches
    ADD COLUMN winner_goes_to_match_id UUID REFERENCES tournament_matches(id) ON DELETE SET NULL;

-- DB-036: Add loser_goes_to_match_id for double elimination
ALTER TABLE tournament_matches
    ADD COLUMN loser_goes_to_match_id UUID REFERENCES tournament_matches(id) ON DELETE SET NULL;

-- DB-037: Add walkover support
ALTER TABLE tournament_matches
    ADD COLUMN is_walkover BOOLEAN DEFAULT FALSE,
    ADD COLUMN walkover_reason TEXT;

-- Add status constraint
ALTER TABLE tournament_matches
    ADD CONSTRAINT valid_match_status
    CHECK (status IN ('pending', 'in_progress', 'completed', 'walkover', 'cancelled'));

-- DB-038: Add indexes to tournament_matches
CREATE INDEX idx_matches_tournament ON tournament_matches(tournament_id);
CREATE INDEX idx_matches_round ON tournament_matches(round_id);
CREATE INDEX idx_matches_winner_goes ON tournament_matches(winner_goes_to_match_id) WHERE winner_goes_to_match_id IS NOT NULL;
CREATE INDEX idx_matches_loser_goes ON tournament_matches(loser_goes_to_match_id) WHERE loser_goes_to_match_id IS NOT NULL;

-- DB-039: Create match_games table for best-of series
CREATE TABLE match_games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES tournament_matches(id) ON DELETE CASCADE,
    game_number INTEGER NOT NULL,
    team_a_score INTEGER DEFAULT 0,
    team_b_score INTEGER DEFAULT 0,
    winner_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add status constraint
ALTER TABLE match_games
    ADD CONSTRAINT valid_game_status
    CHECK (status IN ('pending', 'in_progress', 'completed'));

-- DB-040: Add unique constraint on match_games
ALTER TABLE match_games
    ADD CONSTRAINT unique_game
    UNIQUE(match_id, game_number);

CREATE INDEX idx_games_match ON match_games(match_id);

-- ============================================
-- GROUP PLAY TABLES (DB-041 to DB-044)
-- ============================================

-- DB-041: Create tournament_groups table
CREATE TABLE tournament_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    advance_count INTEGER DEFAULT 2,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_groups_tournament ON tournament_groups(tournament_id);

-- DB-042: Create group_standings table
CREATE TABLE group_standings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES tournament_groups(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES mini_activity_teams(id) ON DELETE CASCADE,
    played INTEGER DEFAULT 0,
    won INTEGER DEFAULT 0,
    drawn INTEGER DEFAULT 0,
    lost INTEGER DEFAULT 0,
    goals_for INTEGER DEFAULT 0,
    goals_against INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    position INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DB-043: Add unique constraint on group_standings
ALTER TABLE group_standings
    ADD CONSTRAINT unique_group_team
    UNIQUE(group_id, team_id);

CREATE INDEX idx_standings_group ON group_standings(group_id);
CREATE INDEX idx_standings_team ON group_standings(team_id);
CREATE INDEX idx_standings_position ON group_standings(group_id, position);

-- DB-044: Create group_matches table
CREATE TABLE group_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES tournament_groups(id) ON DELETE CASCADE,
    team_a_id UUID NOT NULL REFERENCES mini_activity_teams(id) ON DELETE CASCADE,
    team_b_id UUID NOT NULL REFERENCES mini_activity_teams(id) ON DELETE CASCADE,
    team_a_score INTEGER,
    team_b_score INTEGER,
    status VARCHAR(50) DEFAULT 'pending',
    scheduled_time TIMESTAMP WITH TIME ZONE,
    match_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add status constraint
ALTER TABLE group_matches
    ADD CONSTRAINT valid_group_match_status
    CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));

CREATE INDEX idx_group_matches_group ON group_matches(group_id);

-- ============================================
-- QUALIFICATION ROUNDS (DB-045 to DB-046)
-- ============================================

-- DB-045: Create qualification_rounds table
CREATE TABLE qualification_rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    advance_count INTEGER DEFAULT 8,
    sort_direction VARCHAR(10) DEFAULT 'desc',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add sort_direction constraint
ALTER TABLE qualification_rounds
    ADD CONSTRAINT valid_sort_direction
    CHECK (sort_direction IN ('asc', 'desc'));

CREATE INDEX idx_qual_rounds_tournament ON qualification_rounds(tournament_id);

-- DB-046: Create qualification_results table
CREATE TABLE qualification_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qualification_round_id UUID NOT NULL REFERENCES qualification_rounds(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    result_value DECIMAL(10,3) NOT NULL,
    advanced BOOLEAN DEFAULT FALSE,
    rank INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(qualification_round_id, user_id)
);

CREATE INDEX idx_qual_results_round ON qualification_results(qualification_round_id);
CREATE INDEX idx_qual_results_user ON qualification_results(user_id);
CREATE INDEX idx_qual_results_value ON qualification_results(qualification_round_id, result_value);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE tournaments IS 'Tournament configuration for mini-activities';
COMMENT ON TABLE tournament_rounds IS 'Rounds within a tournament (e.g., Quarter-finals, Semi-finals)';
COMMENT ON TABLE tournament_matches IS 'Individual matches within tournament rounds';
COMMENT ON TABLE match_games IS 'Individual games in best-of series matches';
COMMENT ON TABLE tournament_groups IS 'Groups for group play tournaments';
COMMENT ON TABLE group_standings IS 'Team standings within a group';
COMMENT ON TABLE group_matches IS 'Matches within a group play stage';
COMMENT ON TABLE qualification_rounds IS 'Qualification rounds for time/score based advancement';
COMMENT ON TABLE qualification_results IS 'Individual results in qualification rounds';

COMMENT ON COLUMN tournaments.tournament_type IS 'single_elimination, double_elimination, group_play, group_knockout';
COMMENT ON COLUMN tournaments.best_of IS 'Number of games to win (1, 3, 5, or 7)';
COMMENT ON COLUMN tournaments.bronze_final IS 'Whether to play a bronze medal match';
COMMENT ON COLUMN tournaments.seeding_method IS 'How to seed teams: random, ranked, manual';
COMMENT ON COLUMN tournament_rounds.round_type IS 'winners (main bracket), losers (double elim), bronze, final';
COMMENT ON COLUMN tournament_matches.bracket_position IS 'Position in the bracket (for visualization)';
COMMENT ON COLUMN tournament_matches.winner_goes_to_match_id IS 'Next match for the winner';
COMMENT ON COLUMN tournament_matches.loser_goes_to_match_id IS 'Next match for the loser (double elimination)';
