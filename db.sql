-- =========================================================
-- BABYCARE DATABASE SCHEMA (PostgreSQL 12+) - VERSÃO SIMPLIFICADA MVP
-- Ambiente: PostgreSQL
-- Objetivo: Modelo simplificado para MVP focado no essencial da aplicação.
-- =========================================================

-- =========================================================
-- Adiciona a extensão para gerar UUIDs, se não existir
-- =========================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================================
-- Definição de tipos ENUM
-- =========================================================
CREATE TYPE tipo_refeicao_enum AS ENUM('cafe_da_manha','almoco','jantar','lanche','outro');
CREATE TYPE qualidade_sono_enum AS ENUM('excelente','boa','regular','ruim');

-- =========================================================
-- TABELA: usuarios
-- =========================================================
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  avatar_url TEXT,
  -- Campos de configuração movidos para cá
  notificar_remedios BOOLEAN DEFAULT TRUE,
  notificar_eventos BOOLEAN DEFAULT TRUE,
  modo_escuro BOOLEAN DEFAULT FALSE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- TABELA: criancas
-- =========================================================
CREATE TABLE criancas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  nome VARCHAR(100) NOT NULL,
  data_nascimento DATE NULL,
  avatar_url TEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_criancas_usuario ON criancas(usuario_id);

-- =========================================================
-- TABELA: remedios
-- =========================================================
CREATE TABLE remedios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crianca_id UUID NOT NULL REFERENCES criancas(id) ON DELETE CASCADE,
  nome VARCHAR(100) NOT NULL,
  horario TIME NOT NULL,
  dosagem VARCHAR(50) NULL,
  observacoes TEXT,
  ativo BOOLEAN DEFAULT TRUE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_remedios_crianca ON remedios(crianca_id);
CREATE INDEX ix_remedios_horario ON remedios(horario);

-- =========================================================
-- TABELA: localizacao
-- =========================================================
CREATE TABLE localizacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crianca_id UUID NOT NULL REFERENCES criancas(id) ON DELETE CASCADE,
  endereco VARCHAR(255),
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_localizacao_crianca ON localizacao(crianca_id);
CREATE INDEX ix_localizacao_data ON localizacao(data_hora);

-- =========================================================
-- TABELA: eventos_calendario
-- =========================================================
CREATE TABLE eventos_calendario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crianca_id UUID NOT NULL REFERENCES criancas(id) ON DELETE CASCADE,
  titulo VARCHAR(100) NOT NULL,
  descricao TEXT,
  data_evento DATE NOT NULL,
  hora_evento TIME NULL,
  cor_hex VARCHAR(7) DEFAULT '#3b82f6',
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_eventos_crianca ON eventos_calendario(crianca_id);
CREATE INDEX ix_eventos_data ON eventos_calendario(data_evento);

-- =========================================================
-- TABELA: refeicoes
-- =========================================================
CREATE TABLE refeicoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crianca_id UUID NOT NULL REFERENCES criancas(id) ON DELETE CASCADE,
  tipo_refeicao tipo_refeicao_enum DEFAULT 'outro',
  descricao TEXT,
  horario TIME NOT NULL,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_refeicoes_crianca ON refeicoes(crianca_id);
CREATE INDEX ix_refeicoes_data ON refeicoes(data);

-- =========================================================
-- TABELA: sono
-- =========================================================
CREATE TABLE sono (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crianca_id UUID NOT NULL REFERENCES criancas(id) ON DELETE CASCADE,
  hora_inicio TIMESTAMPTZ NOT NULL,
  hora_fim TIMESTAMPTZ NULL,
  duracao_minutos INT GENERATED ALWAYS AS (
    CAST(EXTRACT(EPOCH FROM (hora_fim - hora_inicio)) / 60 AS INT)
  ) STORED,
  qualidade qualidade_sono_enum DEFAULT 'boa',
  observacoes TEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_sono_crianca ON sono(crianca_id);
CREATE INDEX ix_sono_inicio ON sono(hora_inicio);

-- =========================================================
-- TABELA: faq
-- =========================================================
CREATE TABLE faq (
  id SERIAL PRIMARY KEY,
  pergunta TEXT NOT NULL,
  resposta TEXT NOT NULL,
  ativo BOOLEAN DEFAULT TRUE
);

-- =========================================================
-- TABELA: telefones_emergencia (SIMPLIFICADA)
-- =========================================================
CREATE TABLE telefones_emergencia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_contato VARCHAR(100) NOT NULL,
  telefone VARCHAR(25) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_tel_usuario ON telefones_emergencia(usuario_id);

-- =========================================================
-- SEED OPCIONAL (remova em produção)
-- =========================================================
-- Inserir dados apenas se a tabela de usuários estiver vazia
DO $$
DECLARE
    user_id UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios) THEN
        INSERT INTO usuarios (nome, email, senha_hash) VALUES
        ('Usuário Demo', 'demo@babycare.local', '$2y$10$hash_de_exemplo') RETURNING id INTO user_id;

        INSERT INTO criancas (usuario_id, nome, data_nascimento) VALUES (user_id, 'Bebê Demo', '2024-05-10');
    END IF;
END $$;

-- =========================================================
-- FIM DO SCRIPT
-- =========================================================
