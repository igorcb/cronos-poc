# Story 3.4: Lançar horas a partir do dashboard mobile

Status: ready-for-dev

## Story

Como usuário,
Eu quero registrar horas trabalhadas numa tarefa existente direto do dashboard,
so that eu feche o registro do meu trabalho em poucos toques, sem abrir o navegador.

## Acceptance Criteria

**Given** que estou no dashboard e seleciono uma tarefa para "Lançar Horas"
**When** preencho horário de início/fim (ou duração) e confirmo
**Then** a hora é registrada via API (Story 3.3) e os KPIs do dashboard são atualizados imediatamente, sem exigir reload manual
**And** a ação completa em menos de 15 segundos do toque inicial até a confirmação (NFR2)
**And** se o registro falhar, uma mensagem de erro é exibida e os dados preenchidos não são perdidos

## Tasks / Subtasks

- [ ] Adicionar `createTaskItem(payload)` em `services/api.ts` (AC: #1)
  - [ ] `POST /api/v1/task_items`
- [ ] Criar tela `app/task/[id]/log-hours.tsx` (AC: #1)
  - [ ] Campos: horário de início, horário de fim (ou duração — decisão de UI desta story, priorizar o caminho mais rápido de preencher para atender NFR2)
  - [ ] Botão "Confirmar" chama `createTaskItem`
- [ ] Adicionar ação "Lançar Horas" em cada `TaskCard` do dashboard (AC: #1)
  - [ ] Navega para `app/task/[id]/log-hours.tsx` passando o `task_id`
- [ ] Atualizar KPIs do dashboard imediatamente após sucesso (AC: #2)
  - [ ] Usar o totalizador já retornado na resposta de `createTaskItem` (Story 3.3) para atualizar o estado local do dashboard — evitar um novo round-trip de `getDashboard()` se a resposta já traz o dado atualizado
- [ ] Tratar erro de registro (AC: #4)
  - [ ] Mensagem de erro simples, formulário preenchido preservado para nova tentativa (mesmo padrão da Story 3.2)
- [ ] Validar fluxo end-to-end quanto à velocidade (AC: #3)
  - [ ] Do toque em "Lançar Horas" até a confirmação, o caminho deve ser mínimo em número de telas/toques — evitar passos desnecessários (ex: sem tela de confirmação extra)

## Dev Notes

### EPIC CONTEXT: Epic 3 — Gestão de Tarefas e Horas (DM-013)

Última story do Epic 3 e do MVP mobile inteiro. Depende da Story 3.3 (endpoint existir) e da Story 2.4 (tarefas listadas no dashboard, ponto de entrada da ação "Lançar Horas"). Fecha o ciclo completo de valor do produto descrito no PRD (Jornada 1).

**NFR2 (< 15s):** este é o requisito de performance percebida mais crítico do PRD — a UI deve minimizar toques/telas entre "abrir a tela de lançar horas" e "confirmação". Evitar qualquer passo intermediário não essencial (ex: telas de revisão antes de salvar).

**Atualização imediata dos totalizadores (AC #2):** a Story 3.3 já retorna o totalizador atualizado na resposta do `POST /api/v1/task_items` — reaproveitar esse dado para atualizar o estado do dashboard sem precisar de uma segunda chamada a `GET /api/v1/dashboard`, evitando latência extra desnecessária.

**Consistência de UX de erro:** mesmo padrão já estabelecido na Story 3.2 (formulário criar tarefa) — em caso de falha, preservar os dados preenchidos.

### Project Structure Notes

```
services/api.ts               (adiciona createTaskItem)
app/task/[id]/log-hours.tsx
app/dashboard.tsx              (adiciona ação "Lançar Horas" por TaskCard, atualiza KPIs)
```

### References

- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/3-3-criar-endpoint-de-registro-de-hora-na-api.md] — endpoint consumido, já retorna totalizador atualizado
- [Source: _bmad-output/planning-artifacts/mobile/prd-mobile.md#Non-Functional Requirements] — NFR2 (<15s)
- [Source: _bmad-output/planning-artifacts/mobile/prd-mobile.md#User Journeys] — Jornada 1 (lançar horas no fim do dia)

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
