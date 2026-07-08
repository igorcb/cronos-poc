# Story 1.5: Logout

Status: ready-for-dev

## Story

Como usuário,
Eu quero encerrar minha sessão explicitamente,
so that eu possa sair da minha conta no app quando necessário.

## Acceptance Criteria

**Given** que estou autenticado no app
**When** toco em "Sair"
**Then** o token local é removido (`SecureStore`) e o token no backend é invalidado/revogado
**And** sou redirecionado para a tela de login

## Tasks / Subtasks

- [ ] Criar endpoint `DELETE /api/v1/sessions` no backend (AC: #2)
  - [ ] `Api::V1::SessionsController#destroy` — busca o `ApiToken` atual (via `Current.user`/token do header) e faz `destroy`
  - [ ] Rota: `resource :sessions, only: [:create, :destroy]`
  - [ ] Spec em `spec/requests/api/v1/sessions_spec.rb` cobrindo revogação (token deixa de ser aceito após `destroy`)
- [ ] Implementar `AuthContext.logout()` completo (AC: #1, #3)
  - [ ] Chamar `services/api.ts` → `DELETE /api/v1/sessions`
  - [ ] Remover token do `SecureStore` independentemente da resposta do backend (garantir logout local mesmo se a chamada de rede falhar)
  - [ ] Atualizar status para `unauthenticated`
- [ ] Adicionar botão/ação "Sair" na tela de dashboard (AC: #1)
- [ ] Redirecionar para `app/login.tsx` após logout (AC: #3)

## Dev Notes

### EPIC CONTEXT: Epic 1 — Fundação e Autenticação (DM-013)

Última story do Epic 1. Depende da Story 1.2 (model `ApiToken` já existe) e da Story 1.3/1.4 (`AuthContext` e fluxo de sessão já existem). Fecha o ciclo completo de autenticação do app (FR1, FR2, FR3).

**Ordem de operações no logout (importante):** remover o token localmente **mesmo que a chamada de revogação ao backend falhe** (ex: sem internet) — o usuário não deve ficar "preso" logado no app por uma falha de rede. A revogação no backend é best-effort; a garantia client-side é a que importa para a UX.

**Reaproveitamento:** não criar um novo model/controller — apenas adicionar a action `destroy` ao `Api::V1::SessionsController` já criado na Story 1.2.

### Project Structure Notes

```
app/controllers/api/v1/sessions_controller.rb  (adiciona #destroy)
contexts/AuthContext.tsx                        (completa #logout)
app/dashboard.tsx                               (adiciona botão "Sair")
```

### References

- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/1-2-criar-api-de-autenticacao-no-backend.md] — controller/model reaproveitados
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Authentication & Security]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
