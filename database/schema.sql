-- =========================================================================
-- TableFlow Database Schema
-- PostgreSQL + pgvector
-- =========================================================================

-- Enable pgvector extension (run once per database)
CREATE EXTENSION IF NOT EXISTS vector;

-- =========================================================================
-- MENU TABLE
-- Stores restaurant menu items with vector embeddings for semantic search.
-- =========================================================================
CREATE TABLE IF NOT EXISTS menu (
    id              BIGSERIAL PRIMARY KEY,
    nombre_plato    TEXT NOT NULL UNIQUE,
    descripcion     TEXT,
    precio          TEXT,
    tiempo_preparacion TEXT,
    clasificacion   TEXT,
    content         TEXT,
    metadata        JSONB DEFAULT '{}'::jsonb,
    embedding       vector(1536),
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Index for fast cosine similarity search
CREATE INDEX IF NOT EXISTS idx_menu_embedding
    ON menu
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- =========================================================================
-- RESERVATIONS TABLE
-- Stores customer bookings with conflict-safe upsert support.
-- =========================================================================
CREATE TABLE IF NOT EXISTS reservas (
    id                  BIGSERIAL PRIMARY KEY,
    nombre_cliente      TEXT NOT NULL,
    contacto            TEXT NOT NULL,
    cantidad_personas   INTEGER DEFAULT 1,
    fecha               TEXT NOT NULL,
    hora                TEXT NOT NULL,
    estado              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT now(),
    UNIQUE (contacto, fecha, hora)
);

-- =========================================================================
-- CHAT MEMORY TABLES
-- Used by n8n PostgresChat Memory nodes for session persistence.
-- =========================================================================
CREATE TABLE IF NOT EXISTS "Chats_clientes" (
    id          BIGSERIAL PRIMARY KEY,
    session_id  TEXT NOT NULL,
    message     JSONB NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Chat_admin" (
    id          BIGSERIAL PRIMARY KEY,
    session_id  TEXT NOT NULL,
    message     JSONB NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- =========================================================================
-- SUPABASE RPC FUNCTION (for n8n vector store tool)
-- Match menu items by cosine similarity.
-- =========================================================================
CREATE OR REPLACE FUNCTION match_menu (
    query_embedding vector(1536),
    match_count     INT DEFAULT 5,
    filter          JSONB DEFAULT '{}'
)
RETURNS TABLE (
    id              BIGINT,
    content         TEXT,
    metadata        JSONB,
    similarity      FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        m.content,
        m.metadata,
        1 - (m.embedding <=> query_embedding) AS similarity
    FROM menu m
    WHERE m.embedding IS NOT NULL
    ORDER BY m.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
