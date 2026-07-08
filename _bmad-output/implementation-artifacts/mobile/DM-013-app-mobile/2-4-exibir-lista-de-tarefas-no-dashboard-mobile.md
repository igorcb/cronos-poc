# Story 2.4: Exibir lista de tarefas no dashboard mobile

Status: ready-for-dev

## Story

Como usuário,
Eu quero ver a lista das minhas tarefas no dashboard,
so that eu identifique rapidamente qual tarefa lançar horas ou consultar.

## Acceptance Criteria

**Given** que estou na tela de dashboard
**When** os dados de tarefas são carregados
**Then** cada tarefa é exibida com código, nome e status
**And** a lista fica visível junto com os KPIs, sem exigir navegação extra

## Tasks / Subtasks

- [ ] Adicionar `getTasks()` em `services/api.ts` (AC: #1)
  - [ ] `GET /api/v1/tasks`
- [ ] Criar `components/TaskCard.tsx` (AC: #1)
  - [ ] Exibe código, nome e status da tarefa
- [ ] Adicionar seção de lista de tarefas em `app/dashboard.tsx` (AC: #1, #2)
  - [ ] Renderizar `FlatList`/mapeamento de `TaskCard` abaixo dos KPIs (Story 2.2), na mesma tela
  - [ ] Estado de loading local para a lista (pode ser combinado com o loading dos KPIs ou separado)
  - [ ] Erro de rede: `Alert.alert`, sem travar a tela (mesmo padrão da Story 2.2)

## Dev Notes

### EPIC CONTEXT: Epic 2 — Dashboard Mobile (DM-013)

Última story do Epic 2. Depende da Story 2.3 (endpoint existe) e reaproveita a mesma tela `app/dashboard.tsx` criada/expandida nas Stories 1.4/2.2 — não cria uma tela nova, apenas adiciona uma seção.

**UX:** a lista deve aparecer **na mesma tela do dashboard**, sem navegação extra (requisito explícito do AC #2) — reforça a filosofia de "menos toques" do PRD (NFR2).

**Reaproveitamento de padrão:** mesmo client centralizado (`services/api.ts`), mesmo padrão de loading/erro já estabelecido na Story 2.2 — não introduzir um padrão diferente para esta seção.

### Project Structure Notes

```
services/api.ts          (adiciona getTasks)
components/TaskCard.tsx
app/dashboard.tsx         (adiciona seção de lista de tarefas)
```

### References

- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/2-3-criar-endpoint-de-listagem-de-tarefas-na-api.md] — endpoint consumido
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/2-2-exibir-kpis-no-dashboard-mobile.md] — padrão de loading/erro já estabelecido na mesma tela

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
