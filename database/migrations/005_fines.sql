-- Fines system (Botekasse)
-- Migration: 005_fines

-- Fine rules
CREATE TABLE fine_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_fine_rules_team ON fine_rules(team_id);
CREATE INDEX idx_fine_rules_active ON fine_rules(team_id, active);

-- Fines
CREATE TABLE fines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID REFERENCES fine_rules(id) ON DELETE SET NULL,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    offender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'pending',
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    evidence_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_fine_status CHECK (status IN ('pending', 'approved', 'rejected', 'appealed', 'paid'))
);

CREATE INDEX idx_fines_team ON fines(team_id);
CREATE INDEX idx_fines_offender ON fines(offender_id);
CREATE INDEX idx_fines_status ON fines(team_id, status);

-- Fine appeals
CREATE TABLE fine_appeals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fine_id UUID NOT NULL UNIQUE REFERENCES fines(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    extra_fee DECIMAL(10,2),
    decided_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    decided_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_appeal_status CHECK (status IN ('pending', 'accepted', 'rejected'))
);

CREATE INDEX idx_fine_appeals_fine ON fine_appeals(fine_id);
CREATE INDEX idx_fine_appeals_status ON fine_appeals(status);

-- Fine payments
CREATE TABLE fine_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fine_id UUID NOT NULL REFERENCES fines(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    registered_by UUID NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_fine_payments_fine ON fine_payments(fine_id);
