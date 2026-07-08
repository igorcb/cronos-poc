# Story 3.2: Criar tarefa a partir do dashboard mobile

Status: ready-for-dev

## Story

Como usuário,
Eu quero criar uma nova tarefa direto do dashboard,
so that eu registre um trabalho novo sem precisar abrir a web.

## Acceptance Criteria

**Given** que estou no dashboard e toco em "Nova Tarefa"
**When** preencho nome, código e seleciono empresa/projeto (dentre os já existentes) e confirmo
**Then** a tarefa é criada via API (Story 3.1) e aparece imediatamente na lista de tarefas do dashboard
**And** se a criação falhar (ex: erro de rede), uma mensagem de erro é exibida e o formulário permanece preenchido para nova tentativa

## Tasks / Subtasks

- [ ] Adicionar `createTask(payload)` em `services/api.ts` (AC: #1)
  - [ ] `POST /api/v1/tasks`
- [ ] Criar tela `app/task/new.tsx` (AC: #1)
  - [ ] Campo nome, campo código, seletor de empresa/projeto (a partir dos dados já existentes — sem opção de criar empresa/projeto novos, fora do MVP)
  - [ ] Botão "Salvar" chama `createTask`
- [ ] Adicionar botão/ícone "Nova Tarefa" em `app/dashboard.tsx` (AC: #1)
  - [ ] Navega para `app/task/new.tsx` (Expo Router)
- [ ] Atualizar lista de tarefas do dashboard após criação (AC: #1)
  - [ ] Ao voltar do formulário com sucesso, re-buscar `getTasks()` (Story 2.4) ou inserir localmente no estado da lista
- [ ] Tratar erro de criação (AC: #2)
  - [ ] Em erro (rede ou validação 422 do backend), exibir mensagem e **manter os campos preenchidos** para nova tentativa (não limpar o formulário em caso de erro)

## Dev Notes

### EPIC CONTEXT: Epic 3 — Gestão de Tarefas e Horas (DM-013)

Depende da Story 3.1 (endpoint `POST /api/v1/tasks` existir) e da Story 2.4 (lista de tarefas no dashboard já existe, para poder atualizar após criar). Não depende de nenhuma story futura (3.3/3.4 são sobre lançar horas, independentes deste fluxo).

**Origem dos dados de empresa/projeto:** o MVP mobile **não** tem CRUD de empresas/projetos (isso é Growth, ver PRD §Post-MVP Features) — o seletor deve listar apenas empresas/projetos já cadastrados (via web). Se não houver nenhum projeto cadastrado, a tela deve comunicar isso claramente (estado vazio), não travar ou mostrar formulário quebrado. Considerar se é necessário um endpoint auxiliar `GET /api/v1/projects` (ou reaproveitar dados já embutidos na resposta de `GET /api/v1/tasks` se suficiente) — se um endpoint novo for necessário, tratar como tarefa adicional desta story e documentar no File List.

**UX de erro (requisito explícito do AC #2):** diferente de outras telas que só mostram `Alert.alert` e seguem em frente, aqui o formulário preenchido **não pode ser perdido** em caso de erro — preservar o estado local dos campos.

### Project Structure Notes

```
services/api.ts       (adiciona createTask)
app/task/new.tsx
app/dashboard.tsx      (adiciona botão "Nova Tarefa")
```

### References

- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/3-1-criar-endpoint-de-criacao-de-tarefa-na-api.md] — endpoint consumido
- [Source: _bmad-output/planning-artifacts/mobile/prd-mobile.md#User Journeys] — Jornada 2 (criar tarefa pelo celular)

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
