# Story 1.3: Tela de login com Google OAuth no app

Status: ready-for-dev

## Story

Como usuário,
Eu quero fazer login no app usando minha conta Google,
so that eu acesse meus dados sem criar uma nova credencial.

## Acceptance Criteria

**Given** que abro o app pela primeira vez (sem sessão ativa)
**When** toco em "Entrar com Google" na tela de login
**Then** o fluxo OAuth do Google é iniciado e, ao concluir, o app troca o resultado por um token de API (Story 1.2)
**And** o token retornado é armazenado com segurança (`SecureStore`)
**And** sou redirecionado para o dashboard (ainda que vazio/placeholder nesta story)

## Tasks / Subtasks

- [ ] Criar `contexts/AuthContext.tsx` (AC: #2, #3)
  - [ ] `useReducer` com estado `{ token: string | null, user: User | null, status: 'idle' | 'loading' | 'authenticated' | 'unauthenticated' }`
  - [ ] Função `login()` que dispara o fluxo OAuth e chama `services/api.ts`
  - [ ] Função `logout()` (placeholder — implementação completa na Story 1.5)
- [ ] Criar `services/api.ts` com client fetch centralizado (AC: #2)
  - [ ] Função `postSession(googleCredential)` que chama `POST /api/v1/sessions`
  - [ ] Nenhuma tela deve chamar `fetch` diretamente — sempre via este módulo
- [ ] Criar `app/login.tsx` (AC: #1)
  - [ ] Botão "Entrar com Google"
  - [ ] Integração com fluxo OAuth (ex: `expo-auth-session` + provedor Google)
  - [ ] Ao concluir OAuth, chamar `AuthContext.login()` passando a credencial
- [ ] Armazenar token com `expo-secure-store` (AC: #3)
  - [ ] Salvar `token` retornado pelo backend
- [ ] Redirecionar para `app/dashboard.tsx` após sucesso (AC: #4)
  - [ ] Dashboard pode ser placeholder nesta story (conteúdo real vem no Epic 2)
- [ ] Tratar erro de login (fluxo cancelado ou credencial inválida)
  - [ ] Exibir mensagem simples (`Alert.alert`) e permanecer na tela de login

## Dev Notes

### EPIC CONTEXT: Epic 1 — Fundação e Autenticação (DM-013)

Depende da Story 1.1 (projeto existe) e da Story 1.2 (endpoint `POST /api/v1/sessions` existe). Não depende de nenhuma story futura.

**Padrão de estado (arquitetura §Frontend Architecture / Communication Patterns):**
Context API com `useReducer`, contexto principal `AuthContext` — não usar Redux/Zustand.

**Padrão de rede (arquitetura §Structure Patterns):**
Toda chamada de rede centralizada em `services/api.ts`. Nenhuma tela deve chamar `fetch` diretamente — regra de enforcement do projeto.

**Armazenamento seguro do token:**
Usar `expo-secure-store` (ou equivalente indicado pelo Expo SDK vigente) — nunca `AsyncStorage` puro para o token, por ser não-criptografado.

**Mecanismo OAuth → token (decisão de implementação desta story, ver architecture-mobile.md §Gap Analysis):**
A arquitetura deixou este mecanismo em aberto propositalmente. Abordagem sugerida: usar `expo-auth-session` para completar o fluxo OAuth do Google no client, obter uma credencial (ex: `id_token`), e enviar via `services/api.ts` para `POST /api/v1/sessions` (Story 1.2), que troca por um `ApiToken` opaco.

### Tratamento de erro

- Erro de rede/OAuth: `Alert.alert` simples, sem travar a tela (mesmo padrão de erro definido na arquitetura para todo o app, ver §Process Patterns)

### Project Structure Notes

```
app/login.tsx
app/dashboard.tsx (placeholder)
contexts/AuthContext.tsx
services/api.ts
```

### References

- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Frontend Architecture (Mobile)]
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Communication Patterns]
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/1-2-criar-api-de-autenticacao-no-backend.md] — endpoint consumido por esta story

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
