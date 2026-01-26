-- Activities and responses
-- Migration: 002_activities

-- Activities table
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    location VARCHAR(255),
    description TEXT,
    recurrence_type VARCHAR(50) DEFAULT 'once',
    recurrence_end_date DATE,
    response_type VARCHAR(50) DEFAULT 'yes_no',
    response_deadline_hours INTEGER,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_type CHECK (type IN ('training', 'match', 'social', 'other')),
    CONSTRAINT valid_recurrence CHECK (recurrence_type IN ('once', 'weekly', 'biweekly', 'monthly')),
    CONSTRAINT valid_response_type CHECK (response_type IN ('yes_no', 'yes_no_maybe', 'with_deadline', 'opt_out'))
);

CREATE INDEX idx_activities_team ON activities(team_id);

-- Activity instances (individual occurrences)
CREATE TABLE activity_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    status VARCHAR(50) DEFAULT 'scheduled',
    cancelled_reason TEXT,
    CONSTRAINT valid_status CHECK (status IN ('scheduled', 'completed', 'cancelled'))
);

CREATE INDEX idx_activity_instances_activity ON activity_instances(activity_id);
CREATE INDEX idx_activity_instances_date ON activity_instances(date);

-- Activity responses
CREATE TABLE activity_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES activity_instances(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    response VARCHAR(50),
    comment TEXT,
    responded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(instance_id, user_id),
    CONSTRAINT valid_response CHECK (response IS NULL OR response IN ('yes', 'no', 'maybe'))
);

CREATE INDEX idx_activity_responses_instance ON activity_responses(instance_id);
CREATE INDEX idx_activity_responses_user ON activity_responses(user_id);
