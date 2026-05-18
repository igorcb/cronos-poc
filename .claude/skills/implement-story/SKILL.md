---
name: implement-story
description: Pipeline completo de implementação de uma story BMad — branch, dev, QA, ajustes, validação Playwright e PR. Use quando o usuário pedir "implementar story X.Y" ou invocar /implement-story.
---

# Implement Story

## Overview

Pipeline determinístico para levar uma story do estado `ready-for-dev` até PR aberto, passando por implementação, code review do QA, ajustes e validação manual via Playwright MCP.

## Quando usar

- Usuário invoca `/implement-story` ou nomeia uma story específica (ex: "implemente 4.17", "implementa a story 017-form-edit-completo").
- Sempre depois de a story ter sido documentada (status `ready-for-dev` no sprint-status do domínio correspondente).

## Argumentos esperados

O usuário deve fornecer o identificador da story em uma das formas:
- Slug completo: `017-form-edit-completo-todos-dados-task`
- Story ID: `4.17`
- Domínio + número: `DM-004 017`

Se ambíguo, pedir clarificação **antes** de executar qualquer passo.

## Pré-requisitos

Antes de começar, verificar:
- Container `cronos-poc-web-1` está rodando (`docker ps`). Se DB não estiver no ar, subir com `docker compose up -d db`.
- Story existe em `_bmad-output/implementation-artifacts/DM-XXX/NNN-*.md` com status `ready-for-dev`.

## Passos (sequenciais — não pule)

### Passo 1: Localizar a story
1. Procurar o arquivo em `_bmad-output/implementation-artifacts/DM-*/` que corresponde ao slug/ID fornecido.
2. Confirmar status `ready-for-dev`. Se for `done` ou `in-progress`, parar e perguntar ao usuário.
3. Ler o arquivo da story na íntegra — entender contexto, ACs, arquivos a modificar, dependências.

### Passo 2: Atualizar master
1. `git checkout master`
2. `git pull origin master`

### Passo 3: Criar branch
Padrão de nomenclatura: `<feature|fix>-<slug-da-story>`
- Usa `feature-` se a story é nova funcionalidade
- Usa `fix-` se o título/contexto deixa claro que é bug fix
- O slug é o nome do arquivo sem o `.md` (ex: `017-form-edit-completo-todos-dados-task`)

Exemplo: `feature-017-form-edit-completo-todos-dados-task`

Comando: `git checkout -b feature-NNN-slug-da-story`

### Passo 4: Implementação (bmad-agent-dev / Amelia)
Invocar a skill `bmad-agent-dev` com instrução para implementar a story específica:

> Implemente a story `<caminho-do-arquivo-md>` seguindo TODOS os ACs em ordem. Mantenha 100% de cobertura de testes (SimpleCov enforce no spec_helper). Atualize Dev Agent Record e File List no arquivo da story.

Aguardar conclusão. Se houver falha de specs ou cobertura, deixar o dev agent resolver antes de prosseguir.

### Passo 5: Code Review (bmad-agent-qa / Quinn)
Invocar a skill `bmad-agent-qa` ou `bmad-code-review` com instrução:

> Revise a implementação da story `<arquivo>` na branch atual. Categorize findings em CRITICAL, HIGH, MEDIUM, LOW. **Após o review, registre cada finding em `~/.claude/projects/-home-igor-rails-app-cronos-poc/memory/` como feedback do tipo `feedback_qa_<story-id>_<topico>.md` e adicione no `MEMORY.md` index.** Isso evita que erros se repitam em stories futuras.

A memória persiste entre sessões — o dev agent das próximas implementações vai ler e evitar os mesmos erros.

### Passo 6: Aplicar correções do QA (bmad-agent-dev novamente)
Invocar `bmad-agent-dev` com:

> Aplique as correções do QA na story `<arquivo>`. Trate severidades nesta ordem: CRITICAL → HIGH → MEDIUM → LOW. Aplique TODAS. Rode a suite completa após cada categoria e garanta 100% de cobertura. Atualize Dev Agent Record com o que foi ajustado.

### Passo 7: Validação UI via Playwright MCP
Quando a story tiver impacto em UI (form, view, dashboard, etc.), validar via Playwright:

1. Navegar para `http://localhost:3001`
2. Login: `admin@cronos-poc.local` / `password123`
3. Exercitar o fluxo descrito nos ACs da story (criar, editar, deletar, filtrar, etc.)
4. Tirar screenshot do estado final em `.playwright-mcp/<story-slug>-validation.png`
5. Confirmar que cada AC funcional bate visualmente com o esperado

Se a story for puramente backend (callback, helper, query), pular este passo e documentar "Sem impacto de UI — validação via specs apenas".

### Passo 8: Marcar como done
Atualizar o `sprint-status.yaml` do domínio:
- Story: `status: done` + `notes: Implementado via PR #XXX em YYYY-MM-DD`
- Domínio: ajustar `progress`, `done`, `ready_for_dev` e `next_actions`
- Marcar todos os ACs com `[x]` no arquivo da story

### Passo 9: Commit + Push + PR
1. `git add -A`
2. Commit com mensagem descritiva (formato: `feat(área): título da story\n\nResumo do que foi implementado e principais decisões`)
3. `git push -u origin <branch>`
4. `gh pr create --base master --head <branch> --title "..." --body "..."` com:
   - Summary (3-5 bullets do que foi feito)
   - Test plan (validações executadas)
   - Link para o arquivo da story
   - Resultados de specs e cobertura (ex: "861/861 specs, 100% cobertura")
5. Retornar o link do PR ao usuário

## Notas importantes

- **Nunca commit/push sem autorização explícita** se o fluxo for interrompido manualmente. Se o pipeline rodar de ponta a ponta sem interrupção do usuário, o commit/PR final fazem parte do contrato da skill.
- **Sempre rodar a suite completa antes do PR**: `docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec`
- **Coverage 100% é obrigatório** — CI bloqueia. Se cair, o passo 6 não está completo.
- **Memória do QA é cumulativa** — cada finding registrado vira lição para próximas implementações. Não pular essa parte.
- **Em caso de erro no meio do pipeline**: parar, reportar ao usuário com o passo onde travou e o erro exato. Não tentar recuperar silenciosamente.

## Output esperado ao final

```
✅ Story <ID> implementada
🌿 Branch: <nome-da-branch>
📊 Specs: <N>/<N> passing, 100% coverage
🎭 Playwright: <screenshot ou "N/A — backend only">
📝 QA findings: <N> aplicados (X CRITICAL, Y HIGH, Z MEDIUM, W LOW)
🔗 PR: <url>
```
