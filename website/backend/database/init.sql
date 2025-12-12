-- ============================================================
--  Lead-For-NSTEM Database Schema
-- ============================================================

-- ----------------------------
--  Drop existing tables
-- ----------------------------
DROP TABLE IF EXISTS leads;
DROP TABLE IF EXISTS schools;

-- ----------------------------
--  Schools Table
-- ----------------------------
CREATE TABLE schools (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    website VARCHAR(255),
    district VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    grade_low INT,
    grade_high INT
);

-- ----------------------------
--  Leads Table
-- ----------------------------
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    school_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    status VARCHAR(50) DEFAULT 'new'

    CONSTRAINT fk_school
        FOREIGN KEY (school_id)
        REFERENCES schools(id)
        ON DELETE CASCADE
);

-- ----------------------------
--  AI Queries
-- ----------------------------
CREATE TABLE ai_queries (
    id SERIAL PRIMARY KEY,
    lead_id INT,
    prompt TEXT NOT NULL,
    response TEXT NOT NULL,
    model VARCHAR(50),
    tokens_used INT,
    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE SET NULL
);

-- ----------------------------
--  Lead Enrichment
-- ----------------------------
CREATE TABLE lead_enrichment (
    id SERIAL PRIMARY KEY,
    lead_id INT NOT NULL,
    confidence_score NUMERIC(5,2),
    enriched_role VARCHAR(255),
    enriched_category VARCHAR(255),
    enriched_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
);

-- ----------------------------
--  Redis Job Management
-- ----------------------------
CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payload JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ----------------------------
--  Users
-- ----------------------------
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT NOW()
);

-- ----------------------------
--  Error Log
-- ----------------------------
CREATE TABLE error_log (
    id SERIAL PRIMARY KEY,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ----------------------------
--  Imported Batch History
-- ----------------------------
CREATE TABLE import_history (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255),
    records_imported INT,
    imported_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ----------------------------
--  Audit Log
-- ----------------------------
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INT,
    action VARCHAR(255),
    entity_type VARCHAR(50),
    entity_id INT,
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ----------------------------
--  Indexes
-- ----------------------------
CREATE INDEX idx_schools_name ON schools (name);
CREATE INDEX idx_leads_school_id ON leads (school_id);
CREATE INDEX idx_leads_last_name ON leads (last_name);
CREATE INDEX idx_leads_email ON leads (email);
