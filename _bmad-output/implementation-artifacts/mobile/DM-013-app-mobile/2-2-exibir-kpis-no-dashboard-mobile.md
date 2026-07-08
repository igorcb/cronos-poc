# Story 2.2: Exibir KPIs no dashboard mobile

Status: ready-for-dev

## Story

Como usuário,
Eu quero ver meus KPIs de horas e valores ao abrir o app,
so that eu tenha a mesma visão consolidada que tenho na web.

## Acceptance Criteria

**Given** que estou autenticado e chego na tela de dashboard
**When** a tela carrega
**Then** os KPIs (horas do dia, horas do mês, valor do dia, valor do mês) são buscados via `services/api.ts` e exibidos
**And** um estado de carregamento é exibido enquanto os dados não chegam
**And** um erro de rede exibe uma mensagem simples (`Alert.alert`), sem travar a tela

## Tasks / Subtasks

- [ ] Adicionar `getDashboard()` em `services/api.ts` (AC: #1)
  - [ ] `GET /api/v1/dashboard`, injeta header `Authorization: Bearer <token>` automaticamente (client centralizado)
- [ ] Criar `components/KpiTile.tsx` (AC: #1)
  - [ ] Componente reutilizável para exibir um KPI (label + valor)
- [ ] Implementar tela `app/dashboard.tsx` — seção de KPIs (AC: #1, #2, #3)
  - [ ] `useState<boolean>` para loading local
  - [ ] Buscar dados no mount (`useEffect`)
  - [ ] Renderizar 4 `KpiTile`: horas do dia, horas do mês, valor do dia, valor do mês
  - [ ] Exibir indicador de carregamento (ex: `ActivityIndicator`) enquanto `loading === true`
  - [ ] Em erro de rede, `Alert.alert` com mensagem simples e manter a tela visível (sem crash)

## Dev Notes

### EPIC CONTEXT: Epic 2 — Dashboard Mobile (DM-013)

Depende da Story 2.1 (endpoint `GET /api/v1/dashboard` existir) e da Story 1.4 (dashboard já é a tela de destino pós-login). Não depende de Story 2.3/2.4 (lista de tarefas é uma seção independente da mesma tela, adicionada depois).

**Padrão de loading (arquitetura §Process Patterns):** estado local por tela via `useState<boolean>`, sem loading global/context compartilhado.

**Padrão de erro (arquitetura §Process Patterns):** erros de rede tratados no client (`services/api.ts`) e propagados como exceção; a tela captura com try/catch e usa `Alert.alert` nativo — nunca deixar a tela travada ou em branco silenciosamente.

**Regra de rede (enforcement obrigatório):** esta tela NUNCA chama `fetch` diretamente — sempre via `services/api.ts`.

### Project Structure Notes

```
services/api.ts        (adiciona getDashboard)
components/KpiTile.tsx
app/dashboard.tsx       (seção de KPIs)
```

### References

- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/2-1-criar-endpoint-de-dashboard-na-api.md] — endpoint consumido
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Process Patterns]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
