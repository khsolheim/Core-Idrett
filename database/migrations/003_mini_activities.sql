-- Mini-activities and team division
-- Migration: 003_mini_activities

-- Activity templates
CREATE TABLE activity_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    default_points INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_template_type CHECK (type IN ('individual', 'team'))
);

CREATE INDEX idx_activity_templates_team ON activity_templates(team_id);

-- Mini-activities
CREATE TABLE mini_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES activity_instances(id) ON DELETE CASCADE,
    template_id UUID REFERENCES activity_templates(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    division_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_mini_type CHECK (type IN ('individual', 'team')),
    CONSTRAINT valid_division_method CHECK (division_method IS NULL OR division_method IN ('random', 'ranked', 'age'))
);

CREATE INDEX idx_mini_activities_instance ON mini_activities(instance_id);

-- Mini-activity teams
CREATE TABLE mini_activity_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    name VARCHAR(100),
    final_score INTEGER
);

CREATE INDEX idx_mini_activity_teams_mini ON mini_activity_teams(mini_activity_id);

-- Mini-activity participants
CREATE TABLE mini_activity_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_team_id UUID REFERENCES mini_activity_teams(id) ON DELETE CASCADE,
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER DEFAULT 0,
    UNIQUE(mini_activity_id, user_id)
);

CREATE INDEX idx_mini_activity_participants_mini ON mini_activity_participants(mini_activity_id);
CREATE INDEX idx_mini_activity_participants_user ON mini_activity_participants(user_id);
