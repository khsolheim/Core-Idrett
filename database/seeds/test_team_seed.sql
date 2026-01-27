-- Test data: 20 players on a team with varied stats
-- Run this after migrations
-- Note: Actual database does not have seasons, leaderboards, or test_templates tables

-- Create test team
INSERT INTO teams (id, name, sport, invite_code, created_at)
VALUES (
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Nordstrand FK',
    'Fotball',
    'NFKTEST2025',
    NOW()
);

-- Create team settings
INSERT INTO team_settings (team_id, attendance_points, win_points, draw_points, loss_points)
VALUES (
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    1, 3, 1, 0
);

-- Create 20 test users (Norwegian football players)
INSERT INTO users (id, email, password_hash, name, created_at) VALUES
    ('11111111-1111-1111-1111-111111111101', 'magnus.carlsen@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Magnus Carlsen', NOW()),
    ('11111111-1111-1111-1111-111111111102', 'erling.haaland@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Erling Haaland', NOW()),
    ('11111111-1111-1111-1111-111111111103', 'martin.odegaard@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Martin Odegaard', NOW()),
    ('11111111-1111-1111-1111-111111111104', 'sander.berge@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Sander Berge', NOW()),
    ('11111111-1111-1111-1111-111111111105', 'kristian.thorstvedt@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Kristian Thorstvedt', NOW()),
    ('11111111-1111-1111-1111-111111111106', 'alexander.sorloth@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Alexander Sorloth', NOW()),
    ('11111111-1111-1111-1111-111111111107', 'mohamed.elyounoussi@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Mohamed Elyounoussi', NOW()),
    ('11111111-1111-1111-1111-111111111108', 'stefan.strandberg@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Stefan Strandberg', NOW()),
    ('11111111-1111-1111-1111-111111111109', 'leo.ostigard@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Leo Ostigard', NOW()),
    ('11111111-1111-1111-1111-111111111110', 'birger.meling@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Birger Meling', NOW()),
    ('11111111-1111-1111-1111-111111111111', 'marcus.holmgren@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Marcus Holmgren Pedersen', NOW()),
    ('11111111-1111-1111-1111-111111111112', 'fredrik.aursnes@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Fredrik Aursnes', NOW()),
    ('11111111-1111-1111-1111-111111111113', 'morten.thorsby@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Morten Thorsby', NOW()),
    ('11111111-1111-1111-1111-111111111114', 'jens.hauge@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Jens Petter Hauge', NOW()),
    ('11111111-1111-1111-1111-111111111115', 'orjan.nyland@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Orjan Nyland', NOW()),
    ('11111111-1111-1111-1111-111111111116', 'patrick.berg@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Patrick Berg', NOW()),
    ('11111111-1111-1111-1111-111111111117', 'antonio.nusa@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Antonio Nusa', NOW()),
    ('11111111-1111-1111-1111-111111111118', 'oscar.bobb@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Oscar Bobb', NOW()),
    ('11111111-1111-1111-1111-111111111119', 'david.datro@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'David Datro Fofana', NOW()),
    ('11111111-1111-1111-1111-111111111120', 'andreas.schjelderup@test.no', '$2a$10$abcdefghijklmnopqrstuvwxyz123456', 'Andreas Schjelderup', NOW());

-- Add all users as team members (first user is admin)
INSERT INTO team_members (user_id, team_id, role, joined_at) VALUES
    ('11111111-1111-1111-1111-111111111101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'admin', NOW() - INTERVAL '6 months'),
    ('11111111-1111-1111-1111-111111111102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '5 months'),
    ('11111111-1111-1111-1111-111111111103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '5 months'),
    ('11111111-1111-1111-1111-111111111104', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '4 months'),
    ('11111111-1111-1111-1111-111111111105', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'fine_boss', NOW() - INTERVAL '4 months'),
    ('11111111-1111-1111-1111-111111111106', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '3 months'),
    ('11111111-1111-1111-1111-111111111107', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '3 months'),
    ('11111111-1111-1111-1111-111111111108', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '3 months'),
    ('11111111-1111-1111-1111-111111111109', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '2 months'),
    ('11111111-1111-1111-1111-111111111110', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '2 months'),
    ('11111111-1111-1111-1111-111111111111', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '2 months'),
    ('11111111-1111-1111-1111-111111111112', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '1 month'),
    ('11111111-1111-1111-1111-111111111113', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '1 month'),
    ('11111111-1111-1111-1111-111111111114', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '1 month'),
    ('11111111-1111-1111-1111-111111111115', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '3 weeks'),
    ('11111111-1111-1111-1111-111111111116', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '2 weeks'),
    ('11111111-1111-1111-1111-111111111117', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '2 weeks'),
    ('11111111-1111-1111-1111-111111111118', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '1 week'),
    ('11111111-1111-1111-1111-111111111119', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '1 week'),
    ('11111111-1111-1111-1111-111111111120', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'player', NOW() - INTERVAL '3 days');

-- Add player ratings (ELO-like system)
INSERT INTO player_ratings (user_id, team_id, rating, wins, losses, draws, updated_at) VALUES
    ('11111111-1111-1111-1111-111111111102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1285.50, 28, 8, 6, NOW()),
    ('11111111-1111-1111-1111-111111111103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1248.25, 25, 10, 7, NOW()),
    ('11111111-1111-1111-1111-111111111101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1232.00, 24, 11, 8, NOW()),
    ('11111111-1111-1111-1111-111111111106', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1198.75, 21, 13, 5, NOW()),
    ('11111111-1111-1111-1111-111111111104', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1175.50, 20, 14, 6, NOW()),
    ('11111111-1111-1111-1111-111111111107', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1152.25, 19, 15, 5, NOW()),
    ('11111111-1111-1111-1111-111111111105', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1138.00, 18, 16, 4, NOW()),
    ('11111111-1111-1111-1111-111111111112', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1112.50, 16, 17, 6, NOW()),
    ('11111111-1111-1111-1111-111111111114', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1098.25, 15, 18, 5, NOW()),
    ('11111111-1111-1111-1111-111111111108', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1085.00, 14, 18, 7, NOW()),
    ('11111111-1111-1111-1111-111111111109', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1072.75, 13, 19, 6, NOW()),
    ('11111111-1111-1111-1111-111111111113', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1058.50, 12, 20, 5, NOW()),
    ('11111111-1111-1111-1111-111111111110', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1045.25, 11, 20, 7, NOW()),
    ('11111111-1111-1111-1111-111111111116', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1032.00, 10, 21, 6, NOW()),
    ('11111111-1111-1111-1111-111111111111', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1018.75, 9, 21, 8, NOW()),
    ('11111111-1111-1111-1111-111111111115', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 985.50, 7, 23, 5, NOW()),
    ('11111111-1111-1111-1111-111111111117', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 965.25, 6, 18, 4, NOW()),
    ('11111111-1111-1111-1111-111111111118', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 948.00, 5, 16, 3, NOW()),
    ('11111111-1111-1111-1111-111111111119', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 932.75, 4, 14, 2, NOW()),
    ('11111111-1111-1111-1111-111111111120', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 912.50, 2, 8, 1, NOW());

-- Add season stats (2024 season)
INSERT INTO season_stats (user_id, team_id, season_year, attendance_count, total_points, total_goals, total_assists, total_wins, total_losses, total_draws) VALUES
    ('11111111-1111-1111-1111-111111111102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 42, 156, 35, 18, 28, 8, 6),
    ('11111111-1111-1111-1111-111111111103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 40, 142, 12, 28, 25, 10, 7),
    ('11111111-1111-1111-1111-111111111101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 43, 138, 8, 15, 24, 11, 8),
    ('11111111-1111-1111-1111-111111111106', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 38, 127, 22, 10, 21, 13, 5),
    ('11111111-1111-1111-1111-111111111104', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 39, 119, 5, 14, 20, 14, 6),
    ('11111111-1111-1111-1111-111111111107', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 37, 112, 15, 12, 19, 15, 5),
    ('11111111-1111-1111-1111-111111111105', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 38, 108, 7, 9, 18, 16, 4),
    ('11111111-1111-1111-1111-111111111112', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 35, 98, 3, 8, 16, 17, 6),
    ('11111111-1111-1111-1111-111111111114', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 33, 94, 11, 7, 15, 18, 5),
    ('11111111-1111-1111-1111-111111111108', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 34, 89, 2, 3, 14, 18, 7),
    ('11111111-1111-1111-1111-111111111109', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 32, 85, 3, 4, 13, 19, 6),
    ('11111111-1111-1111-1111-111111111113', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 31, 81, 4, 6, 12, 20, 5),
    ('11111111-1111-1111-1111-111111111110', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 30, 76, 1, 5, 11, 20, 7),
    ('11111111-1111-1111-1111-111111111116', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 28, 72, 2, 4, 10, 21, 6),
    ('11111111-1111-1111-1111-111111111111', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 29, 68, 1, 3, 9, 21, 8),
    ('11111111-1111-1111-1111-111111111115', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 25, 54, 0, 0, 7, 23, 5),
    ('11111111-1111-1111-1111-111111111117', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 22, 47, 6, 4, 6, 18, 4),
    ('11111111-1111-1111-1111-111111111118', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 19, 38, 4, 3, 5, 16, 3),
    ('11111111-1111-1111-1111-111111111119', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 15, 29, 3, 2, 4, 14, 2),
    ('11111111-1111-1111-1111-111111111120', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 2024, 8, 15, 1, 1, 2, 8, 1);

-- ===========================================
-- TEST DATA SUMMARY
-- ===========================================
-- Team: Nordstrand FK (Fotball)
-- Invite code: NFKTEST2025
-- Players: 20
-- Season: 2024
--
-- Admin user: magnus.carlsen@test.no
-- Fine boss: kristian.thorstvedt@test.no
--
-- Top 5 players (by total_points):
--   1. Erling Haaland - 156 pts (35 goals, 18 assists)
--   2. Martin Odegaard - 142 pts (12 goals, 28 assists)
--   3. Magnus Carlsen - 138 pts (8 goals, 15 assists)
--   4. Alexander Sorloth - 127 pts (22 goals, 10 assists)
--   5. Sander Berge - 119 pts (5 goals, 14 assists)
--
-- Top 5 players (by rating):
--   1. Erling Haaland - 1285.50
--   2. Martin Odegaard - 1248.25
--   3. Magnus Carlsen - 1232.00
--   4. Alexander Sorloth - 1198.75
--   5. Sander Berge - 1175.50
-- ===========================================
