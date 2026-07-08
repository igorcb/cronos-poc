# Story 1.1: Inicializar projeto mobile

Status: ready-for-dev

## Story

Como desenvolvedor,
Eu quero inicializar o projeto Cronos Mobile com o starter Expo definido na arquitetura,
so that exista uma base de código pronta para implementar as demais funcionalidades.

## Acceptance Criteria

**Given** que não existe ainda um projeto mobile
**When** o comando `npx create-expo-app@latest cronos-mobile --template default@sdk-57` é executado
**Then** um projeto Expo com TypeScript e Expo Router é criado e roda com sucesso via `npx expo start`
**And** a estrutura de pastas segue o definido na arquitetura (`app/`, `contexts/`, `services/`, `components/`, `types/`)

## Tasks / Subtasks

- [ ] Executar `npx create-expo-app@latest cronos-mobile --template default@sdk-57` (AC: #1)
  - [ ] Confirmar que o projeto criado usa TypeScript por padrão
  - [ ] Confirmar que Expo Router está configurado (pasta `app/` com roteamento por arquivo)
- [ ] Criar estrutura de pastas adicional (AC: #2)
  - [ ] Criar `contexts/` (vazio, receberá `AuthContext.tsx` na Story 1.3)
  - [ ] Criar `services/` (vazio, receberá `api.ts` na Story 1.2/2.2)
  - [ ] Criar `components/` (vazio, receberá `KpiTile.tsx`/`TaskCard.tsx` nas Stories 2.2/2.4)
  - [ ] Criar `types/index.ts` com tipos base vazios/placeholder (`Task`, `TaskItem`, `Company`, `Project`)
- [ ] Validar que o projeto roda (AC: #1)
  - [ ] Rodar `npx expo start` e confirmar que abre no Expo Go sem erros
- [ ] Criar `.env.example` com `API_BASE_URL` (placeholder, será usado a partir da Story 1.2)
- [ ] Inicializar repositório git separado para `cronos-mobile/` (fora do repo Rails `cronos-poc`)

## Dev Notes

- Esta é a **primeira story do projeto mobile** — não há "Previous Story Intelligence" a aplicar, é o ponto de partida.
- O `cronos-mobile` é um **repositório novo, separado** do repo Rails `cronos-poc` (ver architecture-mobile.md §Project Structure). Não criar essa pasta dentro do repo Rails.
- SDK 57 foi a versão vigente confirmada via pesquisa no momento da arquitetura (2026-07-07) — se uma versão mais recente estiver disponível ao implementar, usar o comando padrão `create-expo-app@latest` sem fixar `--template default@sdk-57`, mantendo TypeScript + Expo Router como critério não-negociável.
- Não instalar Redux/Zustand/Axios/React Query — arquitetura decidiu deliberadamente por Context API + `fetch` nativo (ver architecture-mobile.md §Frontend Architecture).
- Não criar telas de login/dashboard nesta story — apenas a base do projeto. As telas específicas vêm nas Stories 1.3, 2.2, 3.2, 3.4.

### Project Structure Notes

Estrutura alvo (ver architecture-mobile.md §Project Structure & Boundaries):
```
cronos-mobile/
├── package.json
├── tsconfig.json
├── app.json
├── .env.example
├── app/
│   └── _layout.tsx
├── contexts/
├── services/
├── components/
└── types/
    └── index.ts
```

### References

- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Starter Template Evaluation]
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Project Structure & Boundaries]
- [Source: _bmad-output/planning-artifacts/mobile/epics-mobile.md#Epic 1 — Fundação e Autenticação]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
