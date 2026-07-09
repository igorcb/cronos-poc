# Story 1.1: Inicializar projeto mobile

Status: done

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

- [x] Executar `npx create-expo-app@latest cronos-mobile --template default@sdk-57` (AC: #1)
  - [x] Confirmar que o projeto criado usa TypeScript por padrão
  - [x] Confirmar que Expo Router está configurado (pasta `src/app/` com roteamento por arquivo — starter atual usa layout `src/` com alias `@/*`, não `app/` na raiz)
- [x] Criar estrutura de pastas adicional (AC: #2)
  - [x] Criar `src/contexts/` (vazio, receberá `AuthContext.tsx` na Story 1.3)
  - [x] Criar `src/services/` (vazio, receberá `api.ts` na Story 1.2/2.2)
  - [x] `src/components/` já existia no starter (receberá `KpiTile.tsx`/`TaskCard.tsx` nas Stories 2.2/2.4)
  - [x] Criar `src/types/index.ts` com tipos base (`Task`, `TaskItem`, `Company`, `Project`)
- [x] Validar que o projeto roda (AC: #1)
  - [x] Rodar `npx expo start --web` — Metro Bundler subiu sem erros, confirmou "Using src/app as the root directory for Expo Router"
- [x] Criar `.env.example` com `API_BASE_URL` (placeholder, será usado a partir da Story 1.2)
- [x] Repositório git separado criado automaticamente pelo `create-expo-app` em `/home/igor/rails_app/cronos-mobile` (fora do repo Rails `cronos-poc`)

## Dev Notes

- Esta é a **primeira story do projeto mobile** — não há "Previous Story Intelligence" a aplicar, é o ponto de partida.
- O `cronos-mobile` é um **repositório novo, separado** do repo Rails `cronos-poc` (ver architecture-mobile.md §Project Structure). Não criar essa pasta dentro do repo Rails.
- SDK 57 foi a versão vigente confirmada via pesquisa no momento da arquitetura (2026-07-07) — se uma versão mais recente estiver disponível ao implementar, usar o comando padrão `create-expo-app@latest` sem fixar `--template default@sdk-57`, mantendo TypeScript + Expo Router como critério não-negociável.
- Não instalar Redux/Zustand/Axios/React Query — arquitetura decidiu deliberadamente por Context API + `fetch` nativo (ver architecture-mobile.md §Frontend Architecture).
- Não criar telas de login/dashboard nesta story — apenas a base do projeto. As telas específicas vêm nas Stories 1.3, 2.2, 3.2, 3.4.

### Project Structure Notes

Estrutura alvo definida em architecture-mobile.md §Project Structure & Boundaries previa pastas na raiz (`app/`, `contexts/`, etc). O starter Expo SDK 57 real gera um layout `src/` com alias `@/*` no `tsconfig.json` — a estrutura foi adaptada mantendo a mesma intenção/separação lógica:

```
cronos-mobile/
├── package.json
├── tsconfig.json          # paths: "@/*" -> "./src/*"
├── app.json
├── .env.example
└── src/
    ├── app/                # Expo Router (_layout.tsx, index.tsx, explore.tsx)
    ├── contexts/
    ├── services/
    ├── components/
    ├── constants/
    ├── hooks/
    └── types/
        └── index.ts
```

**Desvio documentado (não bloqueante):** os arquivos-fonte estão sob `src/`, não na raiz do projeto como a árvore original da arquitetura sugeria. Nenhum requisito funcional é afetado — apenas o caminho físico dos arquivos. Próximas stories devem usar o alias `@/` (ex: `@/contexts/AuthContext`) ou caminho relativo a partir de `src/`.

### References

- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Starter Template Evaluation]
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Project Structure & Boundaries]
- [Source: _bmad-output/planning-artifacts/mobile/epics-mobile.md#Epic 1 — Fundação e Autenticação]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

- `npx create-expo-app@latest cronos-mobile --template default@sdk-57` — sucesso, 589 pacotes instalados
- `npx expo start --web` — Metro Bundler iniciado, "Using src/app as the root directory for Expo Router", sem erros

### Completion Notes List

- Projeto criado em `/home/igor/rails_app/cronos-mobile`, repositório git próprio (separado do `cronos-poc`)
- Estrutura real do starter usa `src/` com alias `@/*` — desvio documentado em Project Structure Notes, sem impacto nos requisitos
- Redux/Zustand/Axios/React Query **não** foram instalados, conforme decisão da arquitetura

### File List

- `cronos-mobile/.env.example` (novo)
- `cronos-mobile/src/contexts/.gitkeep` (novo)
- `cronos-mobile/src/services/.gitkeep` (novo)
- `cronos-mobile/src/types/index.ts` (novo)
- Demais arquivos gerados pelo starter `create-expo-app` (commit `8bd26f7`)
