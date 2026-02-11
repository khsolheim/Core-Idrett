-- Migration: 030_index_foreign_keys.sql
-- Add covering indexes for all unindexed foreign key columns.
-- Without these, DELETE/UPDATE on the parent table requires a sequential
-- scan of the child table to check for referencing rows.

-- CREATE INDEX IF NOT EXISTS is used for idempotency.

-- absence_records
CREATE INDEX IF NOT EXISTS idx_absence_records_approved_by ON absence_records (approved_by);

-- achievement_progress
CREATE INDEX IF NOT EXISTS idx_achievement_progress_achievement_id ON achievement_progress (achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_season_id ON achievement_progress (season_id);

-- activities
CREATE INDEX IF NOT EXISTS idx_activities_created_by ON activities (created_by);

-- activity_instances
CREATE INDEX IF NOT EXISTS idx_activity_instances_edited_by ON activity_instances (edited_by);
CREATE INDEX IF NOT EXISTS idx_activity_instances_season_id ON activity_instances (season_id);

-- fine_appeals
CREATE INDEX IF NOT EXISTS idx_fine_appeals_decided_by ON fine_appeals (decided_by);

-- fine_payments
CREATE INDEX IF NOT EXISTS idx_fine_payments_registered_by ON fine_payments (registered_by);

-- fines
CREATE INDEX IF NOT EXISTS idx_fines_approved_by ON fines (approved_by);
CREATE INDEX IF NOT EXISTS idx_fines_reporter_id ON fines (reporter_id);
CREATE INDEX IF NOT EXISTS idx_fines_rule_id ON fines (rule_id);

-- manual_point_adjustments
CREATE INDEX IF NOT EXISTS idx_manual_adjustments_created_by ON manual_point_adjustments (created_by);

-- message_reads
CREATE INDEX IF NOT EXISTS idx_message_reads_recipient_id ON message_reads (recipient_id);
CREATE INDEX IF NOT EXISTS idx_message_reads_team_id ON message_reads (team_id);

-- mini_activities
CREATE INDEX IF NOT EXISTS idx_mini_activities_template_id ON mini_activities (template_id);

-- mini_activity_adjustments
CREATE INDEX IF NOT EXISTS idx_mini_activity_adjustments_created_by ON mini_activity_adjustments (created_by);

-- mini_activity_head_to_head
CREATE INDEX IF NOT EXISTS idx_mini_activity_h2h_user1_id ON mini_activity_head_to_head (user1_id);
CREATE INDEX IF NOT EXISTS idx_mini_activity_h2h_user2_id ON mini_activity_head_to_head (user2_id);

-- mini_activity_participants
CREATE INDEX IF NOT EXISTS idx_mini_activity_participants_mini_team_id ON mini_activity_participants (mini_team_id);

-- mini_activity_player_stats
CREATE INDEX IF NOT EXISTS idx_mini_activity_player_stats_season_id ON mini_activity_player_stats (season_id);
CREATE INDEX IF NOT EXISTS idx_mini_activity_player_stats_team_id ON mini_activity_player_stats (team_id);

-- mini_activity_team_history
CREATE INDEX IF NOT EXISTS idx_mini_activity_team_history_mini_activity_id ON mini_activity_team_history (mini_activity_id);
CREATE INDEX IF NOT EXISTS idx_mini_activity_team_history_mini_team_id ON mini_activity_team_history (mini_team_id);

-- notification_preferences
CREATE INDEX IF NOT EXISTS idx_notification_preferences_team_id ON notification_preferences (team_id);
