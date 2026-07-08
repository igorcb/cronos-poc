---
stepsCompleted: ['step-01-validate-prerequisites-confirmed', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
status: 'complete'
inputDocuments: ['prd-mobile.md', 'architecture-mobile.md']
---

# Cronos POC Mobile - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Cronos POC Mobile, decomposing the requirements from the PRD and Architecture into implementable stories.

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

## Epic List

### Epic 1: Fundação e Autenticação
Usuário consegue instalar/abrir o app, autenticar-se via Google OAuth e permanecer logado entre sessões, sem re-login constante. Entrega standalone: usuário loga e vê que está autenticado.
**FRs covered:** FR1, FR2, FR3, FR10, FR11

### Epic 2: Dashboard Mobile
Usuário autenticado visualiza o dashboard com KPIs/totalizadores e lista de tarefas, replicando a visão da web. Entrega standalone: usuário consegue ver seus dados reais no celular.
**FRs covered:** FR4, FR5

### Epic 3: Gestão de Tarefas e Horas
Usuário consegue criar tarefas e lançar horas trabalhadas diretamente do dashboard, com atualização imediata dos totalizadores. Entrega standalone: fecha o ciclo completo de valor do produto.
**FRs covered:** FR6, FR7, FR8, FR9

## Epic 1: Fundação e Autenticação

Usuário consegue instalar/abrir o app, autenticar-se via Google OAuth e permanecer logado entre sessões.

### Story 1.1: Inicializar projeto mobile

Como desenvolvedor,
Eu quero inicializar o projeto Cronos Mobile com o starter Expo definido na arquitetura,
So that exista uma base de código pronta para implementar as demais funcionalidades.

**Acceptance Criteria:**

**Given** que não existe ainda um projeto mobile
**When** o comando `npx create-expo-app@latest cronos-mobile --template default@sdk-57` é executado
**Then** um projeto Expo com TypeScript e Expo Router é criado e roda com sucesso via `npx expo start`
**And** a estrutura de pastas segue o definido na arquitetura (`app/`, `contexts/`, `services/`, `components/`, `types/`)

### Story 1.2: Criar API de autenticação no backend

Como usuário do app mobile,
Eu quero que o backend exponha um endpoint de autenticação que emita um token de API,
So that o app possa me autenticar sem depender de sessão por cookie.

**Acceptance Criteria:**

**Given** um usuário já autenticado via Google OAuth na web
**When** o app envia as credenciais/código OAuth para `POST /api/v1/sessions`
**Then** o backend valida o usuário e retorna um token de API válido com data de expiração
**And** o token é persistido numa tabela `api_tokens` associada ao usuário
**And** a rota não herda de `ApplicationController` da web (namespace `Api::V1::` isolado)
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/sessions_spec.rb`, sem alterar specs existentes

### Story 1.3: Tela de login com Google OAuth no app

Como usuário,
Eu quero fazer login no app usando minha conta Google,
So that eu acesse meus dados sem criar uma nova credencial.

**Acceptance Criteria:**

**Given** que abro o app pela primeira vez (sem sessão ativa)
**When** toco em "Entrar com Google" na tela de login
**Then** o fluxo OAuth do Google é iniciado e, ao concluir, o app troca o resultado por um token de API (Story 1.2)
**And** o token retornado é armazenado com segurança (`SecureStore`)
**And** sou redirecionado para o dashboard (ainda que vazio/placeholder nesta story)

### Story 1.4: Persistir sessão entre aberturas do app

Como usuário,
Eu quero continuar autenticado ao reabrir o app,
So that eu não precise logar toda vez que uso o app.

**Acceptance Criteria:**

**Given** que já fiz login anteriormente e o token ainda é válido
**When** eu fecho e reabro o app
**Then** sou levado direto ao dashboard, sem passar pela tela de login
**And** se o token estiver expirado ou inválido, sou redirecionado para a tela de login

### Story 1.5: Logout

Como usuário,
Eu quero encerrar minha sessão explicitamente,
So that eu possa sair da minha conta no app quando necessário.

**Acceptance Criteria:**

**Given** que estou autenticado no app
**When** toco em "Sair"
**Then** o token local é removido (`SecureStore`) e o token no backend é invalidado/revogado
**And** sou redirecionado para a tela de login

## Epic 2: Dashboard Mobile

Usuário autenticado visualiza o dashboard com KPIs/totalizadores e lista de tarefas.

### Story 2.1: Criar endpoint de dashboard na API

Como usuário do app mobile,
Eu quero que o backend exponha meus KPIs/totalizadores via API,
So that o app possa exibir os mesmos dados que vejo na web.

**Acceptance Criteria:**

**Given** um usuário autenticado via token
**When** o app chama `GET /api/v1/dashboard`
**Then** o backend retorna os totalizadores diário/mensal (horas, valor) calculados a partir dos mesmos models usados pela web (`Task`, `TaskItem`)
**And** a resposta respeita o isolamento multi-tenant (só retorna dados do usuário autenticado pelo token)
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/dashboard_spec.rb`

### Story 2.2: Exibir KPIs no dashboard mobile

Como usuário,
Eu quero ver meus KPIs de horas e valores ao abrir o app,
So that eu tenha a mesma visão consolidada que tenho na web.

**Acceptance Criteria:**

**Given** que estou autenticado e chego na tela de dashboard
**When** a tela carrega
**Then** os KPIs (horas do dia, horas do mês, valor do dia, valor do mês) são buscados via `services/api.ts` e exibidos
**And** um estado de carregamento é exibido enquanto os dados não chegam
**And** um erro de rede exibe uma mensagem simples (`Alert.alert`), sem travar a tela

### Story 2.3: Criar endpoint de listagem de tarefas na API

Como usuário do app mobile,
Eu quero que o backend exponha minhas tarefas via API,
So that eu veja quais tarefas existem para lançar horas ou consultar.

**Acceptance Criteria:**

**Given** um usuário autenticado via token
**When** o app chama `GET /api/v1/tasks`
**Then** o backend retorna as tarefas do usuário (código, nome, status, empresa/projeto associados)
**And** a resposta respeita o isolamento multi-tenant
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/tasks_spec.rb`

### Story 2.4: Exibir lista de tarefas no dashboard mobile

Como usuário,
Eu quero ver a lista das minhas tarefas no dashboard,
So that eu identifique rapidamente qual tarefa lançar horas ou consultar.

**Acceptance Criteria:**

**Given** que estou na tela de dashboard
**When** os dados de tarefas são carregados
**Then** cada tarefa é exibida com código, nome e status
**And** a lista fica visível junto com os KPIs, sem exigir navegação extra

## Epic 3: Gestão de Tarefas e Horas

Usuário consegue criar tarefas e lançar horas trabalhadas diretamente do dashboard.

### Story 3.1: Criar endpoint de criação de tarefa na API

Como usuário do app mobile,
Eu quero que o backend permita criar uma tarefa via API,
So that eu registre um novo trabalho sem precisar da web.

**Acceptance Criteria:**

**Given** um usuário autenticado via token, com ao menos uma empresa/projeto já cadastrados
**When** o app chama `POST /api/v1/tasks` com nome, código e projeto associado
**Then** a tarefa é criada usando o model `Task` existente, aplicando as mesmas validações da web
**And** a resposta retorna a tarefa criada em JSON (snake_case)
**And** se o projeto não pertencer ao usuário autenticado, a API retorna 404 (nunca 403), consistente com a regra multi-tenant da web
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/tasks_spec.rb`

### Story 3.2: Criar tarefa a partir do dashboard mobile

Como usuário,
Eu quero criar uma nova tarefa direto do dashboard,
So that eu registre um trabalho novo sem precisar abrir a web.

**Acceptance Criteria:**

**Given** que estou no dashboard e toco em "Nova Tarefa"
**When** preencho nome, código e seleciono empresa/projeto (dentre os já existentes) e confirmo
**Then** a tarefa é criada via API (Story 3.1) e aparece imediatamente na lista de tarefas do dashboard
**And** se a criação falhar (ex: erro de rede), uma mensagem de erro é exibida e o formulário permanece preenchido para nova tentativa

### Story 3.3: Criar endpoint de registro de hora na API

Como usuário do app mobile,
Eu quero que o backend permita registrar horas trabalhadas via API,
So that eu lance meu tempo sem precisar da web.

**Acceptance Criteria:**

**Given** um usuário autenticado via token, com uma tarefa existente
**When** o app chama `POST /api/v1/task_items` com a tarefa, horário de início/fim e data
**Then** o `TaskItem` é criado usando o model existente, que calcula `hours_worked` e `value` automaticamente (mesma lógica da web, sem duplicação)
**And** a resposta retorna o totalizador atualizado da tarefa/dashboard
**And** se a tarefa não pertencer ao usuário autenticado, a API retorna 404
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/task_items_spec.rb`

### Story 3.4: Lançar horas a partir do dashboard mobile

Como usuário,
Eu quero registrar horas trabalhadas numa tarefa existente direto do dashboard,
So that eu feche o registro do meu trabalho em poucos toques, sem abrir o navegador.

**Acceptance Criteria:**

**Given** que estou no dashboard e seleciono uma tarefa para "Lançar Horas"
**When** preencho horário de início/fim (ou duração) e confirmo
**Then** a hora é registrada via API (Story 3.3) e os KPIs do dashboard são atualizados imediatamente, sem exigir reload manual
**And** a ação completa em menos de 15 segundos do toque inicial até a confirmação (NFR2)
**And** se o registro falhar, uma mensagem de erro é exibida e os dados preenchidos não são perdidos
