---
stepsCompleted: ['step-01-init', 'step-02-context', 'step-03-starter', 'step-04-decisions', 'step-05-patterns', 'step-06-structure', 'step-07-validation', 'step-08-complete']
status: 'complete'
completedAt: '2026-07-07'
inputDocuments: ['prd-mobile.md']
workflowType: 'architecture'
project_name: 'cronos-poc-mobile'
user_name: 'Igor'
date: '2026-07-07'
---

# Architecture Decision Document - Cronos POC Mobile

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview
**Requisitos Funcionais:** 11 FRs em 5 áreas — Autenticação (OAuth Google, sessão persistente, logout), Dashboard (KPIs, lista de tarefas), Task Management (criar tarefa), Time Tracking (registrar hora, atualização de totalizadores), e Backend Integration (API JSON nova + isolamento multi-tenant).

**Requisitos Não-Funcionais:** Performance (abertura instantânea, ações < 15s, chamadas de API não-bloqueantes) e Security (token auth, isolamento multi-tenant, HTTPS).

**Escala e Complexidade:**
- Escopo é deliberadamente pequeno (POC): 4 telas/fluxos, sem CRUD de empresas/projetos, sem modo offline, sem push
- Complexidade real não está no client mobile (React Native é simples aqui) — está na criação da API JSON no backend Rails, que hoje só serve HTML via Hotwire/Turbo com sessão por cookie

### Technical Constraints & Dependencies
- Backend Rails 8 existente (monolito Hotwire) precisa ganhar uma camada de API JSON nova — não é reaproveitamento direto
- Autenticação atual é `has_secure_password` + Google OAuth via `omniauth-google-oauth2`, com sessão por cookie assinado — para mobile, precisa de uma estratégia de token (ex: JWT ou token opaco com expiração) coexistindo com a auth web existente, sem quebrá-la
- Multi-tenancy hoje é garantida via `Current.user` + scoping em controllers Hotwire — a API precisa replicar essa mesma garantia (404 cross-tenant, nunca 403) através de um caminho de autenticação diferente
- Sem infraestrutura de deploy mobile ainda (Expo/EAS não configurado no projeto)

### Cross-Cutting Concerns Identified
- **Autenticação dupla**: sessão cookie (web) + token (mobile) devem coexistir sem conflito
- **Reuso de regras de negócio**: cálculos de `hours_worked`, `value`, totalizadores devem ser idênticos entre web e API (mesma fonte de verdade, sem duplicar lógica)
- **Versionamento de API**: mesmo em POC, vale decidir se a API já nasce versionada (`/api/v1/...`) para não travar evolução futura

## Starter Template Evaluation

### Primary Technology Domain
Mobile app cross-platform (React Native + Expo), TypeScript, com Context API para estado simples — sem necessidade de Redux/Zustand dado o escopo mínimo do MVP (4 telas).

### Starter Options Considered
- **`create-expo-app` (template `default`)** — template oficial da Expo, TypeScript nativo, navegação básica incluída, mantido ativamente pela própria Expo
- **`create-expo-app --template tabs`** — variante com navegação em abas pré-configurada (Expo Router)
- Templates de terceiros (community) — descartados: adicionam dependências e convenções que não agregam valor a uma POC pequena

### Selected Starter: `create-expo-app` (template default, SDK atual)

**Rationale for Selection:**
É o template oficial, TypeScript de fábrica, com o mínimo de opinião arquitetural — ideal pra POC onde não queremos brigar com convenções de terceiros. Inclui Expo Router (navegação baseada em arquivos), suficiente para as poucas telas do MVP (login, dashboard, criar tarefa, lançar hora).

**Initialization Command:**

```bash
npx create-expo-app@latest cronos-mobile --template default@sdk-57
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:** TypeScript configurado por padrão, Expo SDK 57 (mais recente na transição atual)

**Styling Solution:** Nenhuma opinião imposta — StyleSheet nativo do React Native por padrão

**Build Tooling:** Expo CLI + EAS Build (quando formos além do Expo Go)

**Testing Framework:** Nenhum incluído por padrão — fora do escopo de POC

**Code Organization:** Expo Router (roteamento por arquivo em `app/`)

**Development Experience:** Hot reload via Expo Go, TypeScript, ESLint básico incluído

**Nota:** A inicialização do projeto com esse comando deve ser a primeira story de implementação.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Estratégia de autenticação mobile (token opaco)
- Design da API (REST versionada, controllers separados da web)

**Important Decisions (Shape Architecture):**
- Modelagem de dados (reaproveitar models existentes, sem duplicar lógica)
- Arquitetura frontend (Context API + fetch nativo)
- Infraestrutura (sem deploy novo na fase POC)

**Deferred Decisions (Post-MVP):**
- CI/CD para build mobile (EAS Build) — só quando sair de Expo Go
- Monitoramento/observabilidade do app mobile

### Authentication & Security

**Decisão:** Token opaco gerado no backend Rails, armazenado em `SecureStore` do Expo, enviado via header `Authorization: Bearer <token>`. Login continua via Google OAuth existente; após autenticar, o backend emite um token de API novo (tabela dedicada ou extensão do model `Session` com `expires_at` e discriminação de tipo).

**Rationale:** Evita a complexidade de assinatura/revogação de JWT, que não agrega valor numa POC de poucos usuários. Token opaco com expiração longa resolve o requisito de sessão persistente sem re-login, e é revogável apagando a linha no banco.

**Affects:** Backend (novo model/coluna de token, middleware de auth na API), Mobile (armazenamento seguro do token, interceptor de requisições)

### API & Communication Patterns

**Decisão:** REST JSON versionada desde o início (`/api/v1/...`), com controllers Rails dedicados sob namespace `Api::V1::`, não herdando de `ApplicationController` da web — evita acoplamento com sessão cookie e protege os 1.120 specs existentes de regressão.

**Rationale:** Mantém a web intocada; zero risco de quebrar o sistema em produção. Versionamento desde o início evita retrabalho se a API evoluir após a POC.

**Affects:** Novo namespace de controllers, novo conjunto de request specs isolado dos existentes

### Data Architecture

**Decisão:** Nenhuma mudança de schema além de uma tabela/coluna nova para tokens de API. Controllers da API reutilizam os mesmos models e validators (`Task`, `TaskItem`, `Company`, `Project`) já usados pela web — nenhuma lógica de cálculo (`hours_worked`, `value`) é duplicada.

**Rationale:** Fonte única de verdade, alinhado ao cross-cutting concern identificado na análise de contexto.

**Affects:** Migration nova (tabela de tokens), serializers/views JSON para expor os models existentes

### Frontend Architecture (Mobile)

**Decisão:** Context API para estado de autenticação (token do usuário logado), `fetch` nativo para chamadas à API (sem Axios/React Query), Expo Router para navegação entre as 4 telas do MVP.

**Rationale:** Escopo pequeno (4 telas) não justifica bibliotecas adicionais de data-fetching/state management — alinhado à preferência já definida por Context API simples.

**Affects:** Estrutura de pastas do app (`app/`, `contexts/`, `services/api.ts`)

### Infrastructure & Deployment

**Decisão:** Backend Rails permanece no Railway, sem mudança de infraestrutura de deploy. Mobile, na fase POC, roda via Expo Go (sem build nativo, sem EAS Build, sem loja de apps).

**Rationale:** Zero infraestrutura nova a manter durante a fase de validação — consistente com a estratégia de distribuição já definida no PRD.

**Affects:** Nenhuma mudança em `Dockerfile`/`.railway.json`; app mobile não tem pipeline de deploy próprio ainda

### Decision Impact Analysis

**Implementation Sequence:**
1. Migration + model de token de API no backend
2. Controllers `Api::V1::` (auth, dashboard, tasks, task_items) com specs isolados
3. Inicialização do projeto Expo (`create-expo-app`)
4. Tela de login (OAuth) + armazenamento de token
5. Dashboard mobile consumindo a API
6. Fluxos de criar tarefa e lançar hora

**Cross-Component Dependencies:**
- Mobile depende 100% da API existir antes de qualquer tela funcional além do login
- Token de API e sessão cookie da web coexistem sem interferência (namespaces de auth separados)

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined
7 pontos críticos identificados, dado que o projeto agora cruza duas stacks (Rails/Ruby no backend, TypeScript/React Native no mobile).

### Naming Patterns

**Backend (API) — segue convenção Rails já estabelecida no projeto:**
- Controllers: `Api::V1::TasksController` (namespace + plural + Controller)
- Rotas: `/api/v1/tasks`, `/api/v1/task_items` (plural snake_case)
- Serializers: `Api::V1::TaskSerializer`

**Mobile (TypeScript/React Native):**
- Componentes: `PascalCase` (`DashboardScreen.tsx`, `TaskCard.tsx`)
- Arquivos de rota (Expo Router): `kebab-case`/convenção de arquivo do Expo Router (`app/dashboard.tsx`, `app/task/new.tsx`)
- Funções/variáveis: `camelCase` (`fetchDashboardData`, `taskItems`)
- Hooks customizados: prefixo `use` (`useAuth.ts`, `useApi.ts`)

### Structure Patterns

**Backend:**
- Controllers da API em `app/controllers/api/v1/`
- Specs da API em `spec/requests/api/v1/` (separado dos specs web existentes)

**Mobile:**
```
cronos-mobile/
  app/                 # Expo Router (telas: login, dashboard, task/new, etc.)
  contexts/            # AuthContext (token, usuário logado)
  services/            # api.ts (client fetch centralizado)
  components/          # componentes reutilizáveis (TaskCard, KpiTile)
  types/                # tipos TypeScript compartilhados (Task, TaskItem, Company)
```

### Format Patterns

**API Response:**
- snake_case no JSON (não camelCase) — consistência com o padrão Rails do projeto
```json
{ "id": 1, "hourly_rate": 150.0, "hours_worked": 2.5, "created_at": "2026-07-07T10:00:00Z" }
```
- Datas em ISO 8601
- Sem wrapper `{data: ...}` — resposta direta do recurso
- Erros: `{ "error": "mensagem legível" }`

### Communication Patterns

**Estado (mobile):** Context API com `useReducer` para o estado de autenticação; sem Redux/Zustand. Contexto principal: `AuthContext`.

**Autenticação:** Toda chamada à API passa pelo client centralizado (`services/api.ts`) que injeta o header `Authorization: Bearer <token>` automaticamente.

### Process Patterns

**Error Handling:** Erros de rede/API tratados no client centralizado (`services/api.ts`), propagados como exceção tipada; telas capturam e exibem mensagem simples (`Alert.alert` nativo).

**Loading States:** Estado local por tela (`useState<boolean>`), sem loading global.

### Enforcement Guidelines

**Todos os agentes AI DEVEM:**
- Usar snake_case no JSON da API (nunca camelCase)
- Colocar controllers da API sob `Api::V1::`, nunca misturar com controllers Hotwire existentes
- Centralizar toda chamada de rede no mobile em `services/api.ts`
- Nunca duplicar lógica de cálculo (`hours_worked`, `value`) — sempre delegar ao model Rails existente

## Project Structure & Boundaries

### Complete Project Directory Structure

**Backend (novos arquivos dentro do `cronos-poc` Rails existente):**
```
cronos-poc/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           ├── base_controller.rb       # auth por token, sem herdar de ApplicationController web
│   │           ├── sessions_controller.rb   # login mobile (troca OAuth por token)
│   │           ├── dashboard_controller.rb  # KPIs para o app
│   │           ├── tasks_controller.rb      # index, create
│   │           └── task_items_controller.rb # create
│   ├── models/
│   │   └── api_token.rb                     # novo model
│   └── serializers/
│       └── api/v1/
│           ├── task_serializer.rb
│           └── task_item_serializer.rb
├── config/
│   └── routes.rb                            # namespace :api do namespace :v1 ... end
└── spec/
    └── requests/
        └── api/
            └── v1/
                ├── sessions_spec.rb
                ├── dashboard_spec.rb
                ├── tasks_spec.rb
                └── task_items_spec.rb
```

**Mobile (novo repositório `cronos-mobile`, separado do repo Rails):**
```
cronos-mobile/
├── package.json
├── tsconfig.json
├── app.json                        # config Expo
├── .env.example
├── app/                            # Expo Router
│   ├── _layout.tsx                 # layout raiz + AuthProvider
│   ├── login.tsx
│   ├── dashboard.tsx
│   └── task/
│       ├── new.tsx                 # criar tarefa
│       └── [id]/
│           └── log-hours.tsx       # lançar hora numa tarefa
├── contexts/
│   └── AuthContext.tsx
├── services/
│   └── api.ts                      # client fetch centralizado
├── components/
│   ├── KpiTile.tsx
│   └── TaskCard.tsx
└── types/
    └── index.ts                    # Task, TaskItem, Company, Project
```

### Architectural Boundaries

**API Boundaries:**
- `/api/v1/sessions` (POST) — troca credencial OAuth por token de API
- `/api/v1/dashboard` (GET) — KPIs/totalizadores
- `/api/v1/tasks` (GET, POST) — listar e criar tarefas
- `/api/v1/task_items` (POST) — registrar hora
- Toda rota exige `Authorization: Bearer <token>`, validado em `Api::V1::BaseController`

**Component Boundaries (mobile):**
- Telas (`app/`) nunca chamam `fetch` diretamente — sempre via `services/api.ts`
- `AuthContext` é a única fonte de verdade do token/usuário logado

**Data Boundaries:**
- Backend: API reutiliza os models `Task`/`TaskItem`/`Company`/`Project` existentes — nenhuma tabela nova além de `api_tokens`
- Mobile: sem persistência local de dados de negócio — sempre busca da API; só o token fica persistido (`SecureStore`)

### Requirements to Structure Mapping

- **FR1-FR3 (Authentication):** `app/login.tsx` + `contexts/AuthContext.tsx` + `Api::V1::SessionsController`
- **FR4-FR5 (Dashboard):** `app/dashboard.tsx` + `Api::V1::DashboardController`
- **FR6-FR7 (Task Management):** `app/task/new.tsx` + `Api::V1::TasksController`
- **FR8-FR9 (Time Tracking):** `app/task/[id]/log-hours.tsx` + `Api::V1::TaskItemsController`
- **FR10-FR11 (Backend Integration):** todo o namespace `Api::V1::` + `ApiToken` model

### Integration Points

**Internal Communication:** Mobile → API via HTTPS/REST; nenhuma comunicação em tempo real (sem WebSocket/Turbo Stream no MVP mobile)

**External Integrations:** Google OAuth (reaproveitado do fluxo web para autenticar antes de emitir o token de API)

**Data Flow:** App → `services/api.ts` → `Api::V1::*Controller` → Models Rails existentes → Postgres (mesmo banco da web)

### File Organization Patterns

**Configuration:** `.env.example` no mobile define `API_BASE_URL`; backend usa credentials/ENV já existentes (Railway)

**Source Organization:** Separação clara backend (Rails, dentro do repo existente) vs. mobile (repositório novo, independente)

**Test Organization:** Specs da API ficam isolados em `spec/requests/api/v1/` — não tocam nos 1.120 specs existentes da web

### Development Workflow Integration

**Development Server:** Backend roda local via Docker (como hoje); mobile roda via `npx expo start`, apontando `API_BASE_URL` para o backend local ou Railway

**Build Process:** Backend segue pipeline CI/CD existente; mobile não tem build nesta fase (Expo Go)

**Deployment:** Backend segue deploy Railway existente (push-to-deploy); mobile sem deploy formal na fase POC

## Architecture Validation Results

### Coherence Validation ✅
Todas as decisões trabalham juntas sem conflito: token opaco + API separada + Context API simples formam uma stack coesa e mínima, sem ferramentas redundantes. Naming/formatos são consistentes com as convenções Rails já em produção.

### Requirements Coverage Validation ✅
- **FR1-FR11:** todas as 11 FRs têm componente arquitetural mapeado
- **NFR Performance:** endereçado via Context API leve + fetch direto + token persistido
- **NFR Security:** endereçado via token com expiração, HTTPS, e isolamento multi-tenant reaproveitado dos models existentes

### Implementation Readiness Validation ✅
Decisões críticas documentadas com rationale; padrões de nomenclatura, estrutura de pastas e formato de API cobrem os principais pontos de conflito entre agentes; estrutura de projeto é concreta.

### Gap Analysis Results
Nenhum gap crítico. Gap importante identificado: mecanismo exato de troca "callback OAuth → token de API" (ex: `expo-auth-session`) fica como decisão de implementação da primeira story de autenticação, não bloqueia o resto da arquitetura.

### Architecture Completeness Checklist

**✅ Requirements Analysis** — contexto, escala e constraints mapeados
**✅ Architectural Decisions** — auth, API, dados, frontend, infra documentados com rationale
**✅ Implementation Patterns** — naming, estrutura, formato, comunicação, erros definidos
**✅ Project Structure** — árvore completa backend + mobile, FRs mapeadas

### Architecture Readiness Assessment

**Status geral:** PRONTO PARA IMPLEMENTAÇÃO
**Nível de confiança:** Alto — escopo pequeno, decisões simples e alinhadas ao padrão já usado no projeto web
**Pontos fortes:** zero risco à web existente (namespace de API isolado), reuso máximo de lógica de negócio, stack mobile minimalista adequada à POC
**Áreas para evolução futura:** mecanismo exato OAuth→token (definir na story), estratégia de deploy quando sair do Expo Go

### Implementation Handoff

**Diretrizes para agentes AI:** seguir as decisões documentadas exatamente, usar os padrões de nomenclatura/formato consistentemente, respeitar os limites de estrutura (API isolada, mobile em repo separado).

**Primeira prioridade de implementação:** `npx create-expo-app@latest cronos-mobile --template default@sdk-57` (mobile) + migration/model `ApiToken` (backend), em paralelo.
