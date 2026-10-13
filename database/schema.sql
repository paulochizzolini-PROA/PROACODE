-- ============================================================
-- PROA — SCHEMA V0.1 (RASCUNHO — NÃO FECHADO)
-- Governança Preventiva Condominial — PostgreSQL / Supabase
-- Data: 13/10/2026
-- Status: rascunho inicial. Sujeito ao parecer externo
-- (PROA-REL-V2-001) e à calibração v1.0 → v1.1 (PILOTO-001).
-- ============================================================

-- Tipos (rótulos fixos usados no sistema)
create type perfil_usuario as enum ('consultor', 'dirigente', 'conselho');
create type tipo_cliente as enum ('condominio', 'associacao');
create type semaforo as enum ('verde', 'amarelo', 'vermelho', 'nao_se_aplica');
create type tipo_item as enum ('oficial', 'complementar');
create type status_pa as enum ('aberto', 'em_andamento', 'encaminhado_aps', 'concluido');

-- 1. Clientes (condomínios e associações)
create table condominios ( id uuid primary key default gen_random_uuid(), nome text not null, tipo tipo_cliente not null default 'condominio', endereco text, numero_unidades int, administradora text, status text default 'ativo', criado_em timestamptz default now(), atualizado_em timestamptz default now() );

-- 2. Usuários (espelho do login do Supabase Auth)
create table usuarios ( id uuid primary key references auth.users(id) on delete cascade, nome text not null, email text unique not null, perfil perfil_usuario not null default 'consultor', ativo boolean default true, criado_em timestamptz default now() );

-- 3. Vínculo usuário ↔ condomínio (quem acessa o quê)
create table membros_condominio ( id uuid primary key default gen_random_uuid(), usuario_id uuid not null references usuarios(id) on delete cascade, condominio_id uuid not null references condominios(id) on delete cascade, perfil perfil_usuario not null, criado_em timestamptz default now(), unique (usuario_id, condominio_id) );

-- 4. Blocos da metodologia (B01 a B18)
create table blocos ( id uuid primary key default gen_random_uuid(), codigo text unique not null, nome text not null, ordem int not null );

-- 5. Versões da base de itens (v1.0 → v1.1 → ...)
create table base_versoes ( id uuid primary key default gen_random_uuid(), versao text unique not null, status text default 'rascunho', observacao text, criada_em timestamptz default now() );

-- 6. Itens de controle (738 oficiais + complementares por cliente)
create table itens ( id uuid primary key default gen_random_uuid(), bloco_id uuid not null references blocos(id), versao_id uuid not null references base_versoes(id), codigo text not null, item_numero int, titulo text not null, por_que_faz text, o_que_faz text, como_faz text, criterios_analise text, problemas_identificados text, como_solucionar text, tipo tipo_item default 'oficial', ativo boolean default true, unique (codigo, versao_id) );

-- 7. Avaliações (resposta por item, por cliente, por consultor)
create table avaliacoes ( id uuid primary key default gen_random_uuid(), condominio_id uuid not null references condominios(id) on delete cascade, item_id uuid not null references itens(id), semaforo semaforo not null, nota_campo text, evidencia_texto text, avaliado_por uuid references usuarios(id), avaliado_em timestamptz default now(), sincronizado_em timestamptz, dispositivo text, unique (condominio_id, item_id) );

-- 8. Evidências (fotos/documentos — conteúdo no Storage do Supabase)
create table evidencias ( id uuid primary key default gen_random_uuid(), avaliacao_id uuid references avaliacoes(id) on delete cascade, nome text not null, tipo text, url_storage text, criada_em timestamptz default now() );

-- 9. Pontos de Atenção (PA-Bxx.Iyy-nnn)
create table pontos_atencao ( id uuid primary key default gen_random_uuid(), codigo text unique not null, condominio_id uuid not null references condominios(id) on delete cascade, avaliacao_id uuid references avaliacoes(id), semaforo semaforo not null, nota text, status status_pa default 'aberto', criado_em timestamptz default now(), atualizado_em timestamptz default now() );

-- 10. Planos de Ação (APS-001)
create table planos_acao ( id uuid primary key default gen_random_uuid(), pa_id uuid references pontos_atencao(id), condominio_id uuid not null references condominios(id) on delete cascade, acao text not null, responsavel text, prazo date, status text default 'pendente', criado_em timestamptz default now() );

-- NOTA IMPORTANTE: regras de segurança (RLS — quem pode ver o quê, por
-- condomínio e por perfil), LGPD e as tabelas de EAD, licenças (faixas
-- A–I) e trilha de rastreabilidade entram nas próximas versões deste
-- rascunho, após validação do schema.
