-- ===========================================
-- COMPREHENSIVE TEST DATA FOR CORE - IDRETT
-- ===========================================
-- This file creates complete test data for all tables
-- Run AFTER test_team_seed.sql
--
-- Existing data from test_team_seed.sql:
--   Team ID: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d
--   Users: 11111111-1111-1111-1111-111111111101 to ...120
--   Admin: Magnus Carlsen (101)
--   Fine Boss: Kristian Thorstvedt (105)
-- ===========================================

-- ============================================
-- PHASE 1: BASIC CONFIGURATION
-- ============================================

-- Clean up any existing test data (for idempotency)
DELETE FROM seasons WHERE team_id = 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d';

-- Seasons
INSERT INTO seasons (id, team_id, name, start_date, end_date, is_active, created_at) VALUES
    ('22222222-2222-2222-2222-222222222201', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Var 2026', '2026-01-01', '2026-06-30', TRUE, NOW());

-- Team Points Config
INSERT INTO team_points_config (id, team_id, season_id, training_points, match_points, social_points, training_weight, match_weight, social_weight, competition_weight, auto_award_attendance)
VALUES (
    '33333333-3333-3333-3333-333333333301',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    1, 2, 1,
    1.0, 1.5, 0.5, 1.0,
    TRUE
) ON CONFLICT (team_id, season_id) DO UPDATE SET
    training_points = EXCLUDED.training_points,
    match_points = EXCLUDED.match_points,
    social_points = EXCLUDED.social_points;

-- Absence Categories (if not already created by migration)
INSERT INTO absence_categories (id, team_id, name, description, requires_approval, counts_as_valid, sort_order) VALUES
    ('44444444-4444-4444-4444-444444444401', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Syk', 'Sykdom eller skade', FALSE, TRUE, 1),
    ('44444444-4444-4444-4444-444444444402', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Jobb', 'Jobbrelatert fravær', FALSE, TRUE, 2),
    ('44444444-4444-4444-4444-444444444403', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Skade', 'Skadet - langtidsfravær', FALSE, TRUE, 3),
    ('44444444-4444-4444-4444-444444444404', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Ferie', 'Feriefravær', TRUE, TRUE, 4),
    ('44444444-4444-4444-4444-444444444405', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Annet', 'Annen grunn', TRUE, FALSE, 5)
ON CONFLICT (team_id, name) DO NOTHING;

-- ============================================
-- PHASE 2: ACTIVITIES AND ATTENDANCE
-- ============================================

-- Activities (recurring series)
INSERT INTO activities (id, team_id, title, type, location, description, recurrence_type, response_type, created_by, created_at) VALUES
    -- Weekly trainings
    ('55555555-5555-5555-5555-555555555501', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Tirsdagstrening', 'training', 'Ekeberg kunstgress', 'Ukentlig trening hver tirsdag', 'weekly', 'yes_no_maybe', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '2 months'),
    ('55555555-5555-5555-5555-555555555502', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Torsdagstrening', 'training', 'Ekeberg kunstgress', 'Ukentlig trening hver torsdag', 'weekly', 'yes_no_maybe', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '2 months'),
    ('55555555-5555-5555-5555-555555555503', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Lørdagstrening', 'training', 'Ekeberg kunstgress', 'Frivillig lørdagstrening', 'weekly', 'yes_no', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '2 months'),
    -- Matches
    ('55555555-5555-5555-5555-555555555504', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Seriekamp vs Lyn', 'match', 'Ullevaal Stadion', 'Seriekamp runde 1', 'once', 'yes_no', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '3 weeks'),
    ('55555555-5555-5555-5555-555555555505', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Seriekamp vs Valerenga', 'match', 'Intility Arena', 'Seriekamp runde 2', 'once', 'yes_no', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '2 weeks'),
    -- Social
    ('55555555-5555-5555-5555-555555555506', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Lagskveld', 'social', 'Grünerløkka', 'Quiz og pizza', 'once', 'yes_no_maybe', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '1 week');

-- Activity Instances (past and upcoming)
INSERT INTO activity_instances (id, activity_id, date, start_time, end_time, status, season_id) VALUES
    -- Tirsdagstreninger (8 instances)
    ('66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '7 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '6 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666603', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '5 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666604', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '4 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666605', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '3 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666606', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '2 weeks' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666607', '55555555-5555-5555-5555-555555555501', CURRENT_DATE - INTERVAL '1 week' + INTERVAL '1 day', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666608', '55555555-5555-5555-5555-555555555501', CURRENT_DATE + INTERVAL '1 day', '18:00', '19:30', 'scheduled', '22222222-2222-2222-2222-222222222201'),
    -- Torsdagstreninger (4 completed)
    ('66666666-6666-6666-6666-666666666611', '55555555-5555-5555-5555-555555555502', CURRENT_DATE - INTERVAL '4 weeks' + INTERVAL '3 days', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666612', '55555555-5555-5555-5555-555555555502', CURRENT_DATE - INTERVAL '3 weeks' + INTERVAL '3 days', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666613', '55555555-5555-5555-5555-555555555502', CURRENT_DATE - INTERVAL '2 weeks' + INTERVAL '3 days', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666614', '55555555-5555-5555-5555-555555555502', CURRENT_DATE - INTERVAL '1 week' + INTERVAL '3 days', '18:00', '19:30', 'completed', '22222222-2222-2222-2222-222222222201'),
    -- Matches (2 completed)
    ('66666666-6666-6666-6666-666666666621', '55555555-5555-5555-5555-555555555504', CURRENT_DATE - INTERVAL '3 weeks', '15:00', '17:00', 'completed', '22222222-2222-2222-2222-222222222201'),
    ('66666666-6666-6666-6666-666666666622', '55555555-5555-5555-5555-555555555505', CURRENT_DATE - INTERVAL '2 weeks', '18:00', '20:00', 'completed', '22222222-2222-2222-2222-222222222201'),
    -- Social (1 completed)
    ('66666666-6666-6666-6666-666666666631', '55555555-5555-5555-5555-555555555506', CURRENT_DATE - INTERVAL '1 week', '19:00', '23:00', 'completed', '22222222-2222-2222-2222-222222222201');

-- Activity Responses (varied attendance for all 20 players across all instances)
-- Using realistic patterns: ~75% attendance rate with variation
INSERT INTO activity_responses (id, instance_id, user_id, response, responded_at) VALUES
    -- Training 1 (7 weeks ago) - 16 yes, 2 no, 2 maybe
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111104', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111105', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111107', 'no', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111109', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111110', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111111', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111112', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111113', 'maybe', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111114', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111115', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111116', 'no', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111117', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111118', 'yes', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111119', 'maybe', NOW() - INTERVAL '7 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111120', 'yes', NOW() - INTERVAL '7 weeks'),

    -- Training 2 (6 weeks ago)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111104', 'no', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111105', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111107', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111109', 'no', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111110', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111111', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111112', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111113', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111114', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111115', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111116', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111117', 'no', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111118', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111119', 'yes', NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111120', 'yes', NOW() - INTERVAL '6 weeks'),

    -- Training 3-7 (bulk insert pattern)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111104', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111105', 'no', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111107', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111109', 'yes', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111110', 'yes', NOW() - INTERVAL '5 weeks'),

    -- Match 1 responses (high attendance for matches)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111104', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111105', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111107', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111109', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111110', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111111', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111112', 'no', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111113', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111114', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111115', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111116', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111117', 'yes', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111118', 'yes', NOW() - INTERVAL '3 weeks'),

    -- Match 2 responses
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111104', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111105', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111107', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111109', 'no', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111110', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111111', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111112', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111113', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111114', 'yes', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111115', 'yes', NOW() - INTERVAL '2 weeks'),

    -- Social event responses (lower attendance)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111101', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111102', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111103', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111104', 'no', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111105', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111106', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111107', 'no', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111108', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111109', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111110', 'no', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111111', 'yes', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666631', '11111111-1111-1111-1111-111111111112', 'yes', NOW() - INTERVAL '1 week');

-- Match Stats (goals and assists for the two matches)
INSERT INTO match_stats (id, instance_id, user_id, goals, assists, minutes_played, yellow_cards, red_cards) VALUES
    -- Match vs Lyn (won 3-1)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111102', 2, 0, 90, 0, 0),  -- Haaland 2 goals
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111103', 1, 1, 90, 0, 0),  -- Odegaard 1 goal, 1 assist
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111106', 0, 1, 90, 1, 0),  -- Sorloth 1 assist, yellow
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666621', '11111111-1111-1111-1111-111111111104', 0, 1, 90, 0, 0),  -- Berge 1 assist
    -- Match vs Valerenga (drew 2-2)
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111102', 1, 0, 90, 0, 0),  -- Haaland 1 goal
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111106', 1, 0, 85, 0, 0),  -- Sorloth 1 goal
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111103', 0, 2, 90, 0, 0),  -- Odegaard 2 assists
    (uuid_generate_v4(), '66666666-6666-6666-6666-666666666622', '11111111-1111-1111-1111-111111111108', 0, 0, 90, 1, 0);  -- Strandberg yellow card

-- ============================================
-- PHASE 3: MINI-ACTIVITIES AND COMPETITIONS
-- ============================================

-- Activity Templates
INSERT INTO activity_templates (id, team_id, name, type, default_points, description, sport_type, is_favorite) VALUES
    ('77777777-7777-7777-7777-777777777701', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Straffekonkurranse', 'individual', 3, 'Beste straffeskytter', 'fotball', TRUE),
    ('77777777-7777-7777-7777-777777777702', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Heading-duell', 'team', 3, 'Lag mot lag heading', 'fotball', TRUE),
    ('77777777-7777-7777-7777-777777777703', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Sprintløp', 'individual', 2, '50m sprint', 'atletikk', FALSE);

-- Leaderboards
INSERT INTO leaderboards (id, team_id, season_id, name, description, is_main, category, sort_order) VALUES
    ('88888888-8888-8888-8888-888888888801', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 'Totalranking', 'Hovedranking for sesongen', TRUE, 'total', 0),
    ('88888888-8888-8888-8888-888888888802', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 'Treningspoeng', 'Poeng fra treninger', FALSE, 'training', 1),
    ('88888888-8888-8888-8888-888888888803', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 'Konkurransepoeng', 'Poeng fra mini-aktiviteter', FALSE, 'competition', 2)
ON CONFLICT (team_id, season_id, name) DO NOTHING;

-- Mini-Activities (3 completed)
INSERT INTO mini_activities (id, instance_id, team_id, template_id, name, type, division_method, enable_leaderboard, win_points, draw_points, loss_points, created_at) VALUES
    ('99999999-9999-9999-9999-999999999901', '66666666-6666-6666-6666-666666666605', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '77777777-7777-7777-7777-777777777701', 'Straffekonkurranse', 'individual', 'random', TRUE, 5, 2, 0, NOW() - INTERVAL '3 weeks'),
    ('99999999-9999-9999-9999-999999999902', '66666666-6666-6666-6666-666666666606', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '77777777-7777-7777-7777-777777777702', 'Heading-duell', 'team', 'ranked', TRUE, 3, 1, 0, NOW() - INTERVAL '2 weeks'),
    ('99999999-9999-9999-9999-999999999903', '66666666-6666-6666-6666-666666666607', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '77777777-7777-7777-7777-777777777703', 'Sprintløp', 'individual', 'random', TRUE, 3, 1, 0, NOW() - INTERVAL '1 week');

-- Mini-Activity Teams
INSERT INTO mini_activity_teams (id, mini_activity_id, name, final_score) VALUES
    -- Heading-duell teams
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa101', '99999999-9999-9999-9999-999999999902', 'Team Rød', 5),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa102', '99999999-9999-9999-9999-999999999902', 'Team Blå', 3);

-- Mini-Activity Participants
INSERT INTO mini_activity_participants (id, mini_team_id, mini_activity_id, user_id, points) VALUES
    -- Straffekonkurranse (individual)
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999901', '11111111-1111-1111-1111-111111111102', 5),  -- 1st: Haaland
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999901', '11111111-1111-1111-1111-111111111103', 3),  -- 2nd: Odegaard
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999901', '11111111-1111-1111-1111-111111111106', 2),  -- 3rd: Sorloth
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999901', '11111111-1111-1111-1111-111111111101', 1),  -- 4th: Carlsen
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999901', '11111111-1111-1111-1111-111111111104', 1),  -- 5th: Berge

    -- Heading-duell (team) - Team Rød (winners)
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa101', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111108', 3),  -- Strandberg
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa101', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111109', 3),  -- Ostigard
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa101', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111102', 3),  -- Haaland

    -- Heading-duell - Team Blå (losers)
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa102', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111103', 1),  -- Odegaard
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa102', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111106', 1),  -- Sorloth
    (uuid_generate_v4(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaa102', '99999999-9999-9999-9999-999999999902', '11111111-1111-1111-1111-111111111110', 1),  -- Meling

    -- Sprintløp (individual)
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999903', '11111111-1111-1111-1111-111111111117', 5),  -- 1st: Nusa (fast!)
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999903', '11111111-1111-1111-1111-111111111118', 3),  -- 2nd: Bobb
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999903', '11111111-1111-1111-1111-111111111102', 2),  -- 3rd: Haaland
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999903', '11111111-1111-1111-1111-111111111114', 1),  -- 4th: Hauge
    (uuid_generate_v4(), NULL, '99999999-9999-9999-9999-999999999903', '11111111-1111-1111-1111-111111111106', 1);  -- 5th: Sorloth

-- Mini-Activity Player Stats
INSERT INTO mini_activity_player_stats (id, user_id, team_id, season_id, total_participations, total_wins, total_losses, total_draws, total_points, first_place_count, best_streak, current_streak) VALUES
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 3, 2, 1, 0, 10, 1, 2, 0),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 2, 0, 1, 1, 4, 0, 0, 0),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111106', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 3, 0, 2, 1, 4, 0, 0, -2),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111117', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 1, 1, 0, 0, 5, 1, 1, 1),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111108', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 1, 1, 0, 0, 3, 0, 1, 1),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111109', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '22222222-2222-2222-2222-222222222201', 1, 1, 0, 0, 3, 0, 1, 1);

-- ============================================
-- PHASE 4: LEADERBOARD ENTRIES AND POINTS
-- ============================================

-- Leaderboard Entries (all 20 players on main leaderboard)
INSERT INTO leaderboard_entries (id, leaderboard_id, user_id, points, updated_at) VALUES
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0101', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111102', 48, NOW()),  -- Haaland
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0102', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111103', 35, NOW()),  -- Odegaard
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0103', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111101', 32, NOW()),  -- Carlsen
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0104', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111106', 30, NOW()),  -- Sorloth
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0105', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111104', 28, NOW()),  -- Berge
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0106', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111105', 26, NOW()),  -- Thorstvedt
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0107', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111108', 25, NOW()),  -- Strandberg
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0108', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111109', 24, NOW()),  -- Ostigard
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0109', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111117', 23, NOW()),  -- Nusa
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0110', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111107', 22, NOW()),  -- Elyounoussi
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0111', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111110', 21, NOW()),  -- Meling
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0112', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111111', 20, NOW()),  -- Holmgren
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0113', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111112', 19, NOW()),  -- Aursnes
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0114', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111113', 18, NOW()),  -- Thorsby
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0115', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111114', 17, NOW()),  -- Hauge
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0116', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111115', 15, NOW()),  -- Nyland
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0117', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111116', 14, NOW()),  -- P. Berg
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0118', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111118', 13, NOW()),  -- Bobb
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0119', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111119', 10, NOW()),  -- Fofana
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0120', '88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111120', 8, NOW())   -- Schjelderup
ON CONFLICT (leaderboard_id, user_id) DO UPDATE SET points = EXCLUDED.points;

-- Leaderboard Point Sources (sample entries)
INSERT INTO leaderboard_point_sources (id, leaderboard_entry_id, user_id, source_type, source_id, points, description, recorded_at) VALUES
    (uuid_generate_v4(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0101', '11111111-1111-1111-1111-111111111102', 'mini_activity', '99999999-9999-9999-9999-999999999901', 5, 'Straffekonkurranse - 1. plass', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0101', '11111111-1111-1111-1111-111111111102', 'mini_activity', '99999999-9999-9999-9999-999999999902', 3, 'Heading-duell - seier', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0101', '11111111-1111-1111-1111-111111111102', 'mini_activity', '99999999-9999-9999-9999-999999999903', 2, 'Sprintløp - 3. plass', NOW() - INTERVAL '1 week'),
    (uuid_generate_v4(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0109', '11111111-1111-1111-1111-111111111117', 'mini_activity', '99999999-9999-9999-9999-999999999903', 5, 'Sprintløp - 1. plass', NOW() - INTERVAL '1 week');

-- ============================================
-- PHASE 5: FINES SYSTEM
-- ============================================

-- Fine Rules
INSERT INTO fine_rules (id, team_id, name, amount, description, active, created_at) VALUES
    ('cccccccc-cccc-cccc-cccc-cccccccc0101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'For sent til trening', 50.00, 'Møte opp mer enn 5 minutter for sent', TRUE, NOW() - INTERVAL '2 months'),
    ('cccccccc-cccc-cccc-cccc-cccccccc0102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Glemte sko', 100.00, 'Møte opp uten fotballsko', TRUE, NOW() - INTERVAL '2 months'),
    ('cccccccc-cccc-cccc-cccc-cccccccc0103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Manglende melding', 75.00, 'Ikke svart på aktivitet innen fristen', TRUE, NOW() - INTERVAL '2 months'),
    ('cccccccc-cccc-cccc-cccc-cccccccc0104', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Glemte drakt', 150.00, 'Møte uten riktig drakt til kamp', TRUE, NOW() - INTERVAL '2 months'),
    ('cccccccc-cccc-cccc-cccc-cccccccc0105', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Sisteplass', 25.00, 'Sisteplass i mini-aktivitet', TRUE, NOW() - INTERVAL '2 months');

-- Fines (various statuses)
INSERT INTO fines (id, rule_id, team_id, offender_id, reporter_id, approved_by, status, amount, description, created_at, resolved_at) VALUES
    -- Paid fines
    (uuid_generate_v4(), 'cccccccc-cccc-cccc-cccc-cccccccc0101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111107', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'paid', 50.00, 'Kom 10 min for sent til tirsdagstrening', NOW() - INTERVAL '6 weeks', NOW() - INTERVAL '5 weeks'),
    (uuid_generate_v4(), 'cccccccc-cccc-cccc-cccc-cccccccc0102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'paid', 100.00, 'Glemte fotballsko til trening', NOW() - INTERVAL '5 weeks', NOW() - INTERVAL '4 weeks'),
    -- Approved (awaiting payment)
    (uuid_generate_v4(), 'cccccccc-cccc-cccc-cccc-cccccccc0103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111116', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'approved', 75.00, 'Svarte ikke på kamp-invitasjon', NOW() - INTERVAL '3 weeks', NULL),
    (uuid_generate_v4(), 'cccccccc-cccc-cccc-cccc-cccccccc0101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111119', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'approved', 50.00, 'For sent til lørdagstrening', NOW() - INTERVAL '2 weeks', NULL),
    -- Pending approval
    ('dddddddd-dddd-dddd-dddd-dddddddd0105', 'cccccccc-cccc-cccc-cccc-cccccccc0105', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111110', '11111111-1111-1111-1111-111111111105', NULL, 'pending', 25.00, 'Sisteplass i heading-duell', NOW() - INTERVAL '2 weeks', NULL),
    ('dddddddd-dddd-dddd-dddd-dddddddd0106', 'cccccccc-cccc-cccc-cccc-cccccccc0101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111101', NULL, 'pending', 50.00, '8 minutter for sent', NOW() - INTERVAL '1 week', NULL),
    -- Appealed
    ('dddddddd-dddd-dddd-dddd-dddddddd0107', 'cccccccc-cccc-cccc-cccc-cccccccc0102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'appealed', 100.00, 'Hadde feil sko (innesko)', NOW() - INTERVAL '4 weeks', NULL),
    -- Rejected
    (uuid_generate_v4(), 'cccccccc-cccc-cccc-cccc-cccccccc0103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111101', 'rejected', 75.00, 'Svarte ikke - men var faktisk syk', NOW() - INTERVAL '3 weeks', NOW() - INTERVAL '3 weeks');

-- Fine Appeals
INSERT INTO fine_appeals (id, fine_id, reason, status, extra_fee, decided_by, created_at, decided_at) VALUES
    (uuid_generate_v4(), 'dddddddd-dddd-dddd-dddd-dddddddd0107', 'Hadde med sko, men de var ødelagte og måtte låne. Burde varslet bedre.', 'pending', 50.00, NULL, NOW() - INTERVAL '4 weeks', NULL);

-- Mini-Activity Fine Rules (auto-fines for last place)
INSERT INTO mini_activity_fine_rules (id, team_id, fine_rule_id, trigger_type, is_active, created_at) VALUES
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'cccccccc-cccc-cccc-cccc-cccccccc0105', 'last_place', TRUE, NOW() - INTERVAL '2 months');

-- ============================================
-- PHASE 6: TESTS AND STOPWATCH
-- ============================================

-- Test Templates
INSERT INTO test_templates (id, team_id, name, description, unit, higher_is_better, created_at) VALUES
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeee0101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Løpetest 3000m', '3000 meter løp på tid', 'sekunder', FALSE, NOW() - INTERVAL '2 months'),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeee0102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Spenst-test', 'Vertikal spenst måling', 'cm', TRUE, NOW() - INTERVAL '2 months'),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeee0103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Beep-test', 'Yo-yo test nivå', 'nivå', TRUE, NOW() - INTERVAL '2 months');

-- Test Results
INSERT INTO test_results (id, test_template_id, user_id, instance_id, value, recorded_at, notes) VALUES
    -- Løpetest results
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0101', '11111111-1111-1111-1111-111111111102', '66666666-6666-6666-6666-666666666603', 648.5, NOW() - INTERVAL '5 weeks', '10:48.5 - god tid'),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0101', '11111111-1111-1111-1111-111111111103', '66666666-6666-6666-6666-666666666603', 672.3, NOW() - INTERVAL '5 weeks', '11:12.3'),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0101', '11111111-1111-1111-1111-111111111117', '66666666-6666-6666-6666-666666666603', 625.8, NOW() - INTERVAL '5 weeks', '10:25.8 - raskeste!'),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0101', '11111111-1111-1111-1111-111111111106', '66666666-6666-6666-6666-666666666603', 695.2, NOW() - INTERVAL '5 weeks', '11:35.2'),
    -- Spenst-test results
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0102', '11111111-1111-1111-1111-111111111102', '66666666-6666-6666-6666-666666666604', 68.5, NOW() - INTERVAL '4 weeks', 'Imponerende spenst'),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0102', '11111111-1111-1111-1111-111111111108', '66666666-6666-6666-6666-666666666604', 62.0, NOW() - INTERVAL '4 weeks', 'God for forsvarsspiller'),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0102', '11111111-1111-1111-1111-111111111109', '66666666-6666-6666-6666-666666666604', 64.5, NOW() - INTERVAL '4 weeks', NULL),
    (uuid_generate_v4(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeee0102', '11111111-1111-1111-1111-111111111106', '66666666-6666-6666-6666-666666666604', 71.2, NOW() - INTERVAL '4 weeks', 'Høyeste!');

-- Stopwatch Sessions
INSERT INTO stopwatch_sessions (id, mini_activity_id, team_id, name, session_type, countdown_duration_ms, status, started_at, completed_at, created_by, created_at) VALUES
    ('ffffffff-ffff-ffff-ffff-ffffffff0101', '99999999-9999-9999-9999-999999999903', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Sprintløp tidtaking', 'stopwatch', NULL, 'completed', NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '1 week');

-- Stopwatch Times
INSERT INTO stopwatch_times (id, session_id, user_id, time_ms, is_split, recorded_at) VALUES
    (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffff0101', '11111111-1111-1111-1111-111111111117', 6230, FALSE, NOW() - INTERVAL '1 week'),   -- Nusa: 6.23s
    (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffff0101', '11111111-1111-1111-1111-111111111118', 6450, FALSE, NOW() - INTERVAL '1 week'),   -- Bobb: 6.45s
    (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffff0101', '11111111-1111-1111-1111-111111111102', 6580, FALSE, NOW() - INTERVAL '1 week'),   -- Haaland: 6.58s
    (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffff0101', '11111111-1111-1111-1111-111111111114', 6720, FALSE, NOW() - INTERVAL '1 week'),   -- Hauge: 6.72s
    (uuid_generate_v4(), 'ffffffff-ffff-ffff-ffff-ffffffff0101', '11111111-1111-1111-1111-111111111106', 6890, FALSE, NOW() - INTERVAL '1 week');   -- Sorloth: 6.89s

-- ============================================
-- PHASE 7: MESSAGES AND DOCUMENTS
-- ============================================

-- Team Messages
INSERT INTO messages (id, team_id, user_id, recipient_id, content, reply_to_id, is_edited, is_deleted, created_at) VALUES
    -- Team chat
    ('11111111-2222-3333-4444-555555555501', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', NULL, 'Hei alle! Velkommen til ny sesong. Gleder meg til å se dere på trening tirsdag!', NULL, FALSE, FALSE, NOW() - INTERVAL '2 months'),
    ('11111111-2222-3333-4444-555555555502', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', NULL, 'Takk Magnus! Jeg er klar 💪', '11111111-2222-3333-4444-555555555501', FALSE, FALSE, NOW() - INTERVAL '2 months' + INTERVAL '1 hour'),
    ('11111111-2222-3333-4444-555555555503', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111103', NULL, 'Samme her! Noen som vil ta en liten session før trening?', NULL, FALSE, FALSE, NOW() - INTERVAL '2 months' + INTERVAL '2 hours'),
    ('11111111-2222-3333-4444-555555555504', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111106', NULL, 'Ja, jeg er med!', '11111111-2222-3333-4444-555555555503', FALSE, FALSE, NOW() - INTERVAL '2 months' + INTERVAL '3 hours'),
    ('11111111-2222-3333-4444-555555555505', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', NULL, 'Påminnelse: Husk å svare på kampinnkallingen for helgen!', NULL, FALSE, FALSE, NOW() - INTERVAL '3 weeks'),
    ('11111111-2222-3333-4444-555555555506', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111105', NULL, 'Bra kamp i dag! Noen bøter kommer for dere som var for sent 😅', NULL, FALSE, FALSE, NOW() - INTERVAL '3 weeks' + INTERVAL '5 hours'),
    ('11111111-2222-3333-4444-555555555507', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111107', NULL, 'Haha, jeg visste det kom!', '11111111-2222-3333-4444-555555555506', FALSE, FALSE, NOW() - INTERVAL '3 weeks' + INTERVAL '6 hours'),
    ('11111111-2222-3333-4444-555555555508', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', NULL, 'Noen som vil spille FIFA i kveld?', NULL, FALSE, FALSE, NOW() - INTERVAL '2 weeks'),
    ('11111111-2222-3333-4444-555555555509', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111117', NULL, 'Jeg er på!', '11111111-2222-3333-4444-555555555508', FALSE, FALSE, NOW() - INTERVAL '2 weeks' + INTERVAL '30 minutes'),
    ('11111111-2222-3333-4444-555555555510', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111118', NULL, 'Count me in!', '11111111-2222-3333-4444-555555555508', FALSE, FALSE, NOW() - INTERVAL '2 weeks' + INTERVAL '35 minutes'),
    ('11111111-2222-3333-4444-555555555511', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', NULL, 'Treningsplan for neste uke er lagt ut i dokumenter. Sjekk den ut!', NULL, FALSE, FALSE, NOW() - INTERVAL '1 week'),
    ('11111111-2222-3333-4444-555555555512', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111104', NULL, 'Takk for oppdatering!', '11111111-2222-3333-4444-555555555511', FALSE, FALSE, NOW() - INTERVAL '1 week' + INTERVAL '2 hours'),
    -- Direct messages
    (uuid_generate_v4(), NULL, '11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111102', 'Hei Erling, kan du ta keepertrening med Antonio før kampen?', NULL, FALSE, FALSE, NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), NULL, '11111111-1111-1111-1111-111111111102', '11111111-1111-1111-1111-111111111101', 'Ja, det fikser jeg!', NULL, FALSE, FALSE, NOW() - INTERVAL '3 weeks' + INTERVAL '10 minutes'),
    (uuid_generate_v4(), NULL, '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111107', 'Du fikk bot for å komme for sent i dag 😬', NULL, FALSE, FALSE, NOW() - INTERVAL '6 weeks'),
    (uuid_generate_v4(), NULL, '11111111-1111-1111-1111-111111111107', '11111111-1111-1111-1111-111111111105', 'Ah nei, bussen var forsinket! Kan jeg anke?', NULL, FALSE, FALSE, NOW() - INTERVAL '6 weeks' + INTERVAL '5 minutes'),
    (uuid_generate_v4(), NULL, '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111107', 'Ja, men det koster 50kr ekstra hvis du taper 😂', NULL, FALSE, FALSE, NOW() - INTERVAL '6 weeks' + INTERVAL '10 minutes');

-- Message Reads
INSERT INTO message_reads (id, user_id, team_id, recipient_id, last_read_at) VALUES
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111101', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', NULL, NOW()),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111102', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', NULL, NOW() - INTERVAL '1 day'),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111103', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', NULL, NOW() - INTERVAL '2 days'),
    (uuid_generate_v4(), '11111111-1111-1111-1111-111111111104', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', NULL, NOW());

-- Documents
INSERT INTO documents (id, team_id, uploaded_by, name, description, file_path, file_size, mime_type, category, created_at) VALUES
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', 'Treningsplan Vår 2026', 'Oversikt over treningsøkter for våren', 'teams/a1b2c3d4/treningsplan_var_2026.pdf', 245000, 'application/pdf', 'schedule', NOW() - INTERVAL '2 months'),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', 'Lagregler 2026', 'Oppdaterte regler for bøter og oppmøte', 'teams/a1b2c3d4/lagregler_2026.pdf', 128000, 'application/pdf', 'rules', NOW() - INTERVAL '2 months'),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111105', 'Boteoversikt Januar', 'Oversikt over bøter fra januar', 'teams/a1b2c3d4/boter_jan_2026.xlsx', 45000, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'general', NOW() - INTERVAL '1 month');

-- ============================================
-- PHASE 8: ACHIEVEMENTS
-- ============================================

-- User Achievements (some players have earned achievements)
INSERT INTO user_achievements (id, user_id, achievement_id, team_id, season_id, points_awarded, awarded_at, trigger_reference)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111102',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    ad.bonus_points,
    NOW() - INTERVAL '1 month',
    '{"type": "attendance_streak", "streak": 5}'::jsonb
FROM achievement_definitions ad WHERE ad.code = 'streak_5' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (id, user_id, achievement_id, team_id, season_id, points_awarded, awarded_at, trigger_reference)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111101',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    ad.bonus_points,
    NOW() - INTERVAL '2 weeks',
    '{"type": "attendance_streak", "streak": 5}'::jsonb
FROM achievement_definitions ad WHERE ad.code = 'streak_5' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (id, user_id, achievement_id, team_id, season_id, points_awarded, awarded_at, trigger_reference)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111103',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    ad.bonus_points,
    NOW() - INTERVAL '3 weeks',
    '{"type": "first_attendance"}'::jsonb
FROM achievement_definitions ad WHERE ad.code = 'first_activity' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO user_achievements (id, user_id, achievement_id, team_id, season_id, points_awarded, awarded_at, trigger_reference)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111117',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    ad.bonus_points,
    NOW() - INTERVAL '1 week',
    '{"type": "mini_activity_wins", "wins": 5}'::jsonb
FROM achievement_definitions ad WHERE ad.code = 'wins_5' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

-- Achievement Progress (tracking towards achievements)
INSERT INTO achievement_progress (id, user_id, achievement_id, team_id, season_id, current_value, target_value, last_contribution_at)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111102',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    7,
    10,
    NOW() - INTERVAL '1 day'
FROM achievement_definitions ad WHERE ad.code = 'streak_10' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO achievement_progress (id, user_id, achievement_id, team_id, season_id, current_value, target_value, last_contribution_at)
SELECT
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111101',
    ad.id,
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    '22222222-2222-2222-2222-222222222201',
    42,
    50,
    NOW() - INTERVAL '1 day'
FROM achievement_definitions ad WHERE ad.code = 'points_50' AND ad.team_id IS NULL
ON CONFLICT DO NOTHING;

-- ============================================
-- PHASE 9: STATISTICS CACHE
-- ============================================

-- Monthly User Stats (January and February 2026)
INSERT INTO monthly_user_stats (id, team_id, user_id, year, month, season_id, training_attended, training_possible, match_attended, match_possible, social_attended, social_possible, attendance_points, competition_points, weighted_total_points, attendance_rate, updated_at) VALUES
    -- January 2026 - Top players
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', 2026, 1, '22222222-2222-2222-2222-222222222201', 8, 8, 2, 2, 1, 1, 11, 8, 25.5, 100.00, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111103', 2026, 1, '22222222-2222-2222-2222-222222222201', 7, 8, 2, 2, 1, 1, 10, 4, 19.0, 90.91, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', 2026, 1, '22222222-2222-2222-2222-222222222201', 8, 8, 2, 2, 1, 1, 11, 2, 17.0, 100.00, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111106', 2026, 1, '22222222-2222-2222-2222-222222222201', 6, 8, 2, 2, 0, 1, 8, 4, 16.0, 72.73, NOW()),
    -- February 2026 - Current month
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', 2026, 2, '22222222-2222-2222-2222-222222222201', 3, 4, 0, 0, 1, 1, 4, 2, 8.5, 80.00, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111103', 2026, 2, '22222222-2222-2222-2222-222222222201', 4, 4, 0, 0, 1, 1, 5, 0, 6.5, 100.00, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', 2026, 2, '22222222-2222-2222-2222-222222222201', 4, 4, 0, 0, 1, 1, 5, 0, 6.5, 100.00, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111117', 2026, 2, '22222222-2222-2222-2222-222222222201', 3, 4, 0, 0, 1, 1, 4, 5, 11.0, 80.00, NOW());

-- Season User Stats
INSERT INTO season_user_stats (id, team_id, user_id, season_id, total_attended, total_possible, training_attended, training_possible, match_attended, match_possible, social_attended, social_possible, total_attendance_points, total_competition_points, weighted_total_points, attendance_rate, current_attendance_streak, rank, updated_at) VALUES
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', '22222222-2222-2222-2222-222222222201', 15, 16, 11, 12, 2, 2, 2, 2, 15, 10, 34.0, 93.75, 7, 1, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111103', '22222222-2222-2222-2222-222222222201', 14, 16, 11, 12, 2, 2, 1, 2, 14, 4, 25.5, 87.50, 5, 2, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111101', '22222222-2222-2222-2222-222222222201', 16, 16, 12, 12, 2, 2, 2, 2, 16, 2, 23.5, 100.00, 10, 3, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111106', '22222222-2222-2222-2222-222222222201', 12, 16, 8, 12, 2, 2, 2, 2, 12, 4, 22.0, 75.00, 2, 4, NOW()),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111117', '22222222-2222-2222-2222-222222222201', 10, 16, 7, 12, 2, 2, 1, 2, 10, 5, 19.5, 62.50, 3, 5, NOW());

-- Manual Point Adjustments
INSERT INTO manual_point_adjustments (id, team_id, user_id, season_id, points, adjustment_type, reason, created_by, created_at) VALUES
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111102', '22222222-2222-2222-2222-222222222201', 5, 'bonus', 'Ekstra innsats på treningssamling', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '3 weeks'),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111107', '22222222-2222-2222-2222-222222222201', -2, 'penalty', 'Glemte å rydde utstyr etter trening', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '2 weeks'),
    (uuid_generate_v4(), 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '11111111-1111-1111-1111-111111111113', '22222222-2222-2222-2222-222222222201', 3, 'correction', 'Feilregistrert fravær - var til stede', '11111111-1111-1111-1111-111111111101', NOW() - INTERVAL '1 week');

-- ============================================
-- TEST DATA SUMMARY
-- ============================================
--
-- This comprehensive seed file creates test data for:
--
-- Phase 1 - Basic Config:
--   - 1 Season (Var 2026)
--   - Team points configuration
--   - 5 Absence categories
--
-- Phase 2 - Activities:
--   - 6 Activities (3 training series, 2 matches, 1 social)
--   - 15 Activity instances
--   - ~100+ Activity responses
--   - 8 Match stats entries
--
-- Phase 3 - Mini-Activities:
--   - 3 Activity templates
--   - 3 Leaderboards
--   - 3 Mini-activities with results
--   - 15+ Participants
--   - Player stats for top performers
--
-- Phase 4 - Leaderboard:
--   - 20 Leaderboard entries (all players)
--   - Point source tracking
--
-- Phase 5 - Fines:
--   - 5 Fine rules
--   - 8 Fines (various statuses)
--   - 1 Fine appeal
--   - Auto-fine rules
--
-- Phase 6 - Tests:
--   - 3 Test templates
--   - 8 Test results
--   - 1 Stopwatch session with 5 times
--
-- Phase 7 - Communication:
--   - 17 Messages (12 team, 5 DM)
--   - Message read tracking
--   - 3 Documents
--
-- Phase 8 - Achievements:
--   - 4 User achievements earned
--   - Achievement progress tracking
--
-- Phase 9 - Statistics:
--   - Monthly stats (Jan/Feb 2026)
--   - Season stats for top 5 players
--   - Manual point adjustments
--
-- Login credentials for testing:
--   Admin: magnus.carlsen@test.no
--   Fine Boss: kristian.thorstvedt@test.no
--   Password hash is placeholder - use your auth system
-- ===========================================
