-- ============================================================
--  Lead-For-NSTEM Database Schema
-- ============================================================

-- ----------------------------
--  Drop existing tables (order matters for foreign keys)
-- ----------------------------
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS import_history CASCADE;
DROP TABLE IF EXISTS error_log CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS lead_enrichment CASCADE;
DROP TABLE IF EXISTS ai_queries CASCADE;
DROP TABLE IF EXISTS leads CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ----------------------------
--  ENUM Types
-- ----------------------------
CREATE TYPE lead_status AS ENUM ('new', 'contacted', 'interested', 'qualified', 'disqualified', 'converted');
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'standard', 'viewer');

-- ----------------------------
--  Users Table
-- ----------------------------
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);

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
    grade_low INT CHECK (grade_low >= 0 AND grade_low <= 12),
    grade_high INT CHECK (grade_high >= 0 AND grade_high <= 12 AND grade_high >= grade_low),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_schools_name ON schools(name);
CREATE INDEX idx_schools_city_state ON schools(city, state);
CREATE INDEX idx_schools_district ON schools(district);

-- ----------------------------
--  Leads Table
-- ----------------------------
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    school_id INT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(255),
    email VARCHAR(254),
    phone VARCHAR(20),
    status lead_status DEFAULT 'new',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_email_format CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_phone_format CHECK (phone IS NULL OR phone ~ '^\+?[0-9\s\-()]+$')
);

CREATE INDEX idx_leads_school_id ON leads(school_id);
CREATE INDEX idx_leads_last_name ON leads(last_name);
CREATE INDEX idx_leads_email ON leads(email) WHERE email IS NOT NULL;
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);

-- ----------------------------
--  AI Queries Table
-- ----------------------------
CREATE TABLE ai_queries (
    id SERIAL PRIMARY KEY,
    lead_id INT REFERENCES leads(id) ON DELETE SET NULL,
    prompt TEXT NOT NULL,
    response TEXT NOT NULL,
    model VARCHAR(50),
    tokens_used INT CHECK (tokens_used > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_queries_lead_id ON ai_queries(lead_id);
CREATE INDEX idx_ai_queries_created_at ON ai_queries(created_at DESC);

-- ----------------------------
--  Lead Enrichment Table
-- ----------------------------
CREATE TABLE lead_enrichment (
    id SERIAL PRIMARY KEY,
    lead_id INT NOT NULL UNIQUE REFERENCES leads(id) ON DELETE CASCADE,
    confidence_score NUMERIC(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    enriched_role VARCHAR(255),
    enriched_category VARCHAR(255),
    enriched_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lead_enrichment_confidence ON lead_enrichment(confidence_score DESC);

-- ----------------------------
--  Jobs Table
-- ----------------------------
CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(100) NOT NULL,
    status job_status DEFAULT 'pending',
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);
CREATE INDEX idx_jobs_type_status ON jobs(job_type, status);

-- ----------------------------
--  Error Log Table
-- ----------------------------
CREATE TABLE error_log (
    id SERIAL PRIMARY KEY,
    error_message TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_error_log_created_at ON error_log(created_at DESC);

-- ----------------------------
--  Import History Table
-- ----------------------------
CREATE TABLE import_history (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    records_imported INT CHECK (records_imported >= 0),
    imported_by INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_import_history_imported_by ON import_history(imported_by);
CREATE INDEX idx_import_history_created_at ON import_history(created_at DESC);

-- ----------------------------
--  Audit Log Table
-- ----------------------------
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);
