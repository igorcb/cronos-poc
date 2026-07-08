# Story 1.4: Persistir sessão entre aberturas do app

Status: ready-for-dev

## Story

Como usuário,
Eu quero continuar autenticado ao reabrir o app,
so that eu não precise logar toda vez que uso o app.

## Acceptance Criteria

**Given** que já fiz login anteriormente e o token ainda é válido
**When** eu fecho e reabro o app
**Then** sou levado direto ao dashboard, sem passar pela tela de login
**And** se o token estiver expirado ou inválido, sou redirecionado para a tela de login

## Tasks / Subtasks

- [ ] Adicionar bootstrap de sessão no `AuthContext` (AC: #1, #2)
  - [ ] No mount inicial (`_layout.tsx`/`AuthProvider`), ler token do `SecureStore`
  - [ ] Se token existir, validar contra o backend (ex: chamar `GET /api/v1/dashboard` ou um endpoint leve de verificação — reaproveitar `Api::V1::BaseController#authenticate_via_token!` da Story 1.2)
  - [ ] Se válido → status `authenticated`, navegar para `app/dashboard.tsx`
  - [ ] Se inválido/expirado/ausente → status `unauthenticated`, navegar para `app/login.tsx`
- [ ] Exibir estado de carregamento (splash simples) enquanto a validação inicial ocorre (AC: #1)
- [ ] Tratar erro de rede na validação inicial (ex: sem internet) — não deslogar o usuário só por falha de rede, apenas quando o backend explicitamente responder 401

## Dev Notes

### EPIC CONTEXT: Epic 1 — Fundação e Autenticação (DM-013)

Depende da Story 1.3 (login funcionando e token sendo salvo). É o que entrega a NFR1 do PRD ("abertura do app até o dashboard carregado deve ser percebida como instantânea, sem tela de loading de login a cada abertura").

**Importante:** não confundir "token ausente" com "erro de rede". Se a chamada de validação falhar por timeout/sem-conexão, o comportamento correto é manter o usuário na tela de dashboard com os dados em cache/placeholder e tentar de novo, não forçar logout — só um `401` explícito do backend deve derrubar a sessão local.

**Reaproveitamento:** a validação de token nesta story usa o mesmo mecanismo de autenticação da `Api::V1::BaseController` (Story 1.2) — não criar um endpoint novo só para isso, a menos que nenhuma chamada leve exista ainda (nesse caso, um `GET /api/v1/dashboard` mesmo vazio já serve como "ping" de validação).

### Project Structure Notes

```
contexts/AuthContext.tsx  (adiciona bootstrap de sessão)
app/_layout.tsx           (usa status do AuthContext para decidir rota inicial)
```

### References

- [Source: _bmad-output/planning-artifacts/mobile/prd-mobile.md#Non-Functional Requirements] — NFR1 (abertura instantânea)
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/1-3-tela-de-login-com-google-oauth-no-app.md] — AuthContext criado nesta story anterior

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
