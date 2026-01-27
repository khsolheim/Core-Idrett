-- Phase 4: Chat, Documents, Export
-- Migration: 009_phase4_features

-- ============================================
-- TEAM CHAT/MESSAGES
-- ============================================

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_team ON messages(team_id);
CREATE INDEX idx_messages_user ON messages(user_id);
CREATE INDEX idx_messages_created ON messages(team_id, created_at DESC);
CREATE INDEX idx_messages_reply ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;

-- Message read status (for tracking unread messages)
CREATE TABLE message_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, team_id)
);

CREATE INDEX idx_message_reads_user ON message_reads(user_id);

-- ============================================
-- TEAM DOCUMENTS
-- ============================================

-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    file_path VARCHAR(500) NOT NULL,  -- Path in Supabase storage
    file_size INTEGER NOT NULL,  -- Size in bytes
    mime_type VARCHAR(100) NOT NULL,
    category VARCHAR(50),  -- Optional category: 'general', 'rules', 'schedule', etc.
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_documents_team ON documents(team_id);
CREATE INDEX idx_documents_uploaded_by ON documents(uploaded_by);
CREATE INDEX idx_documents_category ON documents(team_id, category);
CREATE INDEX idx_documents_created ON documents(team_id, created_at DESC);

-- ============================================
-- EXPORT LOGS (for tracking exports)
-- ============================================

CREATE TABLE export_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    export_type VARCHAR(50) NOT NULL,  -- 'leaderboard', 'attendance', 'fines'
    file_format VARCHAR(20) NOT NULL,  -- 'csv', 'xlsx', 'pdf'
    parameters JSONB,  -- Any filters/parameters used
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_export_logs_team ON export_logs(team_id);
CREATE INDEX idx_export_logs_user ON export_logs(user_id);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE messages IS 'Team chat messages';
COMMENT ON TABLE message_reads IS 'Tracks last read message per user per team for unread counts';
COMMENT ON TABLE documents IS 'Team documents stored in Supabase storage';
COMMENT ON TABLE export_logs IS 'Audit log for data exports';
