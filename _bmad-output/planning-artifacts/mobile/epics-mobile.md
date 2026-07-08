---
stepsCompleted: ['step-01-validate-prerequisites-confirmed', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
status: 'planned'
totalEpics: 3
totalStories: 13
inputDocuments: ['prd-mobile.md', 'architecture-mobile.md', 'DM-013-app-mobile/product-brief.md']
---

# Cronos POC Mobile - Epic Breakdown (DM-013)

**Status:** 0/13 stories entregues — planejamento concluído, pronto para sprint planning.

---

## Resumo dos Epics

| # | Epic | Domínio | Stories | Status |
|---|------|---------|---------|--------|
| 1 | Fundação e Autenticação | DM-013 | 5 | 🔵 ready-for-dev |
| 2 | Dashboard Mobile | DM-013 | 4 | 🔵 ready-for-dev |
| 3 | Gestão de Tarefas e Horas | DM-013 | 4 | 🔵 ready-for-dev |
| **TOTAL** | | | **13** | **0 done + 13 planejadas** |

---

## Requirements Inventory

### Functional Requirements

FR1: Usuário pode autenticar-se no app via Google OAuth
FR2: Usuário permanece autenticado entre sessões do app, sem precisar logar novamente a cada abertura
FR3: Usuário pode encerrar sessão (logout) explicitamente
FR4: Usuário visualiza, ao abrir o app, um dashboard com os totalizadores/KPIs de horas e valores (diário/mensal), equivalente ao da web
FR5: Usuário visualiza a lista de tarefas associadas às suas empresas/projetos
FR6: Usuário pode criar uma nova tarefa (Task) selecionando uma empresa e projeto já existentes
FR7: Usuário visualiza os dados de uma tarefa (código, nome, status) a partir do dashboard
FR8: Usuário pode registrar horas trabalhadas (TaskItem) vinculadas a uma tarefa existente, informando início/fim ou duração
FR9: Usuário visualiza a atualização dos totalizadores do dashboard imediatamente após registrar horas
FR10: Sistema expõe uma API JSON autenticada por token para consumo do app mobile (capacidade nova no backend Rails, hoje inexistente)
FR11: Sistema aplica as mesmas regras de isolamento multi-tenant (por usuário) já usadas na web, também via API

### NonFunctional Requirements

NFR1: Abertura do app até o dashboard carregado deve ser percebida como instantânea (sem tela de loading de login a cada abertura)
NFR2: Ações de criar tarefa/lançar hora completam em menos de 15 segundos, do toque no ícone até a confirmação
NFR3: Chamadas à API respondem em tempo que não bloqueie a interação do usuário
NFR4: Autenticação por token (não cookie), com expiração/renovação adequada para uso mobile
NFR5: API aplica o mesmo isolamento multi-tenant por usuário já usado na web
NFR6: Comunicação entre app e backend via HTTPS

### Additional Requirements

- **Starter Template (Epic 1 Story 1):** `npx create-expo-app@latest cronos-mobile --template default@sdk-57` — TypeScript, Expo Router, sem opinião de estilo
- Backend precisa de um novo namespace `Api::V1::` isolado dos controllers Hotwire existentes (não deve herdar de `ApplicationController` web)
- Novo model/migration `ApiToken` para autenticação mobile
- Specs da API isolados em `spec/requests/api/v1/` — não podem tocar nos 1.120 specs existentes
- Distribuição via Expo Go na fase POC (sem EAS Build, sem loja de apps)
- JSON da API em snake_case, sem wrapper `{data: ...}`, erros como `{ "error": "..." }`
- Estado de auth no mobile via Context API (`AuthContext`) com `useReducer`, sem Redux/Zustand
- Toda chamada de rede centralizada em `services/api.ts` (nenhuma tela chama `fetch` direto)

### UX Design Requirements

Nenhum documento de UX Design foi criado para este projeto — não há UX-DRs formais. As telas seguem o padrão visual/funcional já validado na web (KPIs do dashboard, formulários de tarefa/hora), sem componentização de design system definida previamente.

### FR Coverage Map

```
FR1: Epic 1 - Login via Google OAuth
FR2: Epic 1 - Sessão persistente (token)
FR3: Epic 1 - Logout
FR10: Epic 1 - API JSON autenticada por token
FR11: Epic 1 - Isolamento multi-tenant na API
FR4: Epic 2 - Dashboard com KPIs
FR5: Epic 2 - Lista de tarefas
FR6: Epic 3 - Criar tarefa
FR7: Epic 3 - Visualizar dados da tarefa
FR8: Epic 3 - Registrar horas (TaskItem)
FR9: Epic 3 - Atualização de totalizadores após lançamento
```

## Epic 1 — Fundação e Autenticação (DM-013)

Usuário consegue instalar/abrir o app, autenticar-se via Google OAuth e permanecer logado entre sessões, sem re-login constante. Entrega standalone: usuário loga e vê que está autenticado.
**FRs covered:** FR1, FR2, FR3, FR10, FR11

- 1.1 Inicializar projeto mobile (starter Expo `create-expo-app` SDK 57, TypeScript, Expo Router) 🔵
- 1.2 API de autenticação no backend (`POST /api/v1/sessions`, model `ApiToken`, namespace `Api::V1::` isolado) 🔵
- 1.3 Tela de login com Google OAuth no app (`SecureStore`) 🔵
- 1.4 Persistir sessão entre aberturas do app 🔵
- 1.5 Logout (revogação de token local + backend) 🔵

## Epic 2 — Dashboard Mobile (DM-013)

Usuário autenticado visualiza o dashboard com KPIs/totalizadores e lista de tarefas, replicando a visão da web. Entrega standalone: usuário consegue ver seus dados reais no celular.
**FRs covered:** FR4, FR5

- 2.1 Endpoint de dashboard na API (`GET /api/v1/dashboard`) 🔵
- 2.2 Exibir KPIs no dashboard mobile via `services/api.ts` 🔵
- 2.3 Endpoint de listagem de tarefas na API (`GET /api/v1/tasks`) 🔵
- 2.4 Exibir lista de tarefas no dashboard mobile 🔵

## Epic 3 — Gestão de Tarefas e Horas (DM-013)

Usuário consegue criar tarefas e lançar horas trabalhadas diretamente do dashboard, com atualização imediata dos totalizadores. Entrega standalone: fecha o ciclo completo de valor do produto.
**FRs covered:** FR6, FR7, FR8, FR9

- 3.1 Endpoint de criação de tarefa na API (`POST /api/v1/tasks`, reaproveita model `Task`, 404 em cross-tenant) 🔵
- 3.2 Criar tarefa a partir do dashboard mobile 🔵
- 3.3 Endpoint de registro de hora na API (`POST /api/v1/task_items`, reaproveita cálculo de `TaskItem`) 🔵
- 3.4 Lançar horas a partir do dashboard mobile (NFR2: <15s) 🔵

---

*Detalhamento completo de cada story (Acceptance Criteria em Given/When/Then, Dev Notes, Tasks/Subtasks) é gerado individualmente em `_bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/` no momento em que cada story for iniciada, via `bmad-create-story` — mesmo padrão usado nos domínios web (ver DM-012).*
