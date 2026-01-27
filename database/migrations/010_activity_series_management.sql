-- Activity Series Management
-- Migration: 010_activity_series_management
-- Purpose: Add support for editing/deleting individual instances in activity series

-- Add columns to activity_instances for series management
ALTER TABLE activity_instances
  ADD COLUMN is_detached BOOLEAN DEFAULT false,
  ADD COLUMN title_override VARCHAR(255),
  ADD COLUMN location_override VARCHAR(255),
  ADD COLUMN description_override TEXT,
  ADD COLUMN start_time_override TIME,
  ADD COLUMN end_time_override TIME,
  ADD COLUMN date_override DATE,
  ADD COLUMN edited_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN edited_by UUID REFERENCES users(id);

-- Index for efficient series queries
CREATE INDEX idx_activity_instances_series
  ON activity_instances(activity_id, date, is_detached);

-- Add activity_updated notification preference
ALTER TABLE notification_preferences
  ADD COLUMN activity_updated BOOLEAN DEFAULT true;

-- Comment explaining the override pattern
COMMENT ON COLUMN activity_instances.is_detached IS
  'When true, this instance is detached from the series and will be skipped during bulk edits';
COMMENT ON COLUMN activity_instances.title_override IS
  'Instance-specific title override. Use COALESCE(title_override, activity.title) for effective value';
COMMENT ON COLUMN activity_instances.location_override IS
  'Instance-specific location override';
COMMENT ON COLUMN activity_instances.description_override IS
  'Instance-specific description override';
COMMENT ON COLUMN activity_instances.start_time_override IS
  'Instance-specific start time override';
COMMENT ON COLUMN activity_instances.end_time_override IS
  'Instance-specific end time override';
COMMENT ON COLUMN activity_instances.date_override IS
  'Instance-specific date override (only for detached instances)';
