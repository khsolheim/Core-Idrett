-- Direct Messages Migration
-- Migration: 013_direct_messages
-- Adds support for private 1-to-1 messaging between users

-- Add recipient_id for private messages
ALTER TABLE messages ADD COLUMN recipient_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Make team_id nullable (null for private messages)
ALTER TABLE messages ALTER COLUMN team_id DROP NOT NULL;

-- Index for finding private conversations efficiently
CREATE INDEX idx_messages_recipient ON messages(recipient_id) WHERE recipient_id IS NOT NULL;
CREATE INDEX idx_messages_direct_chat ON messages(user_id, recipient_id) WHERE recipient_id IS NOT NULL;

-- Constraint: Either team_id OR recipient_id must be set (not both, not neither)
ALTER TABLE messages ADD CONSTRAINT chk_message_target
  CHECK ((team_id IS NOT NULL AND recipient_id IS NULL) OR
         (team_id IS NULL AND recipient_id IS NOT NULL));

-- Update message_reads for private chat support
ALTER TABLE message_reads ALTER COLUMN team_id DROP NOT NULL;
ALTER TABLE message_reads ADD COLUMN recipient_id UUID REFERENCES users(id);

-- Drop the old unique constraint and add a new one that includes recipient_id
ALTER TABLE message_reads DROP CONSTRAINT IF EXISTS message_reads_user_id_team_id_key;
ALTER TABLE message_reads ADD CONSTRAINT message_reads_unique
  UNIQUE(user_id, team_id, recipient_id);

-- Index for direct message reads
CREATE INDEX idx_message_reads_direct ON message_reads(user_id, recipient_id) WHERE recipient_id IS NOT NULL;
