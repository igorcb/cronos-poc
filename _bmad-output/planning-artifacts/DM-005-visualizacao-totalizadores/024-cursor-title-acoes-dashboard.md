---
storyId: '5.24'
epicId: 'DM-005'
status: 'ready-for-development'
createdAt: '2026-06-19'
---

# Story 5.24: Cursor e title nas ações da listagem do Dashboard

## Contexto

Na listagem de tarefas do Dashboard (`_task_row.html.erb`), as colunas de ação "Lançar horas"
e "Entregar tarefa" usam ícones (sem texto) como botão/link. Ao passar o mouse sobre os botões
**ativos**, o cursor aparece como seta padrão em vez da mãozinha (cursor pointer) — provavelmente
porque o preflight do Tailwind v4 reseta `cursor: default` em `button`/`a`. Os estados
**desabilitados** (`span role="button"` com `cursor-not-allowed`) já estão corretos.

Além disso, nenhum dos dois botões possui `title`, dificultando a identificação rápida da ação
ao passar o mouse (tooltip nativo do browser).

### Evidência observada

| Elemento | Arquivo:linha | cursor | title |
|---|---|---|---|
| Lançar horas (ativo) | `_task_row.html.erb:26-29` | seta (sem `cursor-pointer`) | ausente |
| Entregar tarefa (ativo) | `_task_row.html.erb:37-42` | seta (sem `cursor-pointer`) | ausente |
| Lançar horas (desabilitado) | `_task_row.html.erb:17-24` | `cursor-not-allowed` ✅ | n/a (aria-disabled) |
| Entregar tarefa (desabilitado) | `_task_row.html.erb:48-55` | `cursor-not-allowed` ✅ | n/a (aria-disabled) |

Mudança é puramente de apresentação (CSS + atributo HTML), sem impacto em lógica de negócio,
controller ou banco de dados.

## Histórias de usuário

### HU1: Cursor de mãozinha nos botões ativos

**Como** usuário do Dashboard
**Quero** ver o cursor de mãozinha (pointer) ao passar o mouse sobre os botões ativos de
"Lançar horas" e "Entregar tarefa"
**Para** ter um feedback visual claro de que são elementos clicáveis

**Critérios de Aceite:**
- [ ] AC1: Botão ativo "Lançar horas" (`link_to`) tem classe `cursor-pointer`
- [ ] AC2: Botão ativo "Entregar tarefa" (`button_to`) tem classe `cursor-pointer`
- [ ] AC3: Estados desabilitados continuam com `cursor-not-allowed` (sem alteração)

**Estimativa:** 1 story point (~0,5 hora)

### HU2: Title nos botões de ação

**Como** usuário do Dashboard
**Quero** ver um tooltip (title) ao passar o mouse sobre "Lançar horas" e "Entregar tarefa"
**Para** confirmar a ação antes de clicar, sem depender só do ícone

**Critérios de Aceite:**
- [ ] AC1: Botão ativo "Lançar horas" tem `title: "Lançar horas para #{task.display_name}"`
  (mesmo texto do `aria-label`)
- [ ] AC2: Botão ativo "Entregar tarefa" tem `title: "Marcar #{task.display_name} como entregue"`
  (mesmo texto do `aria-label`)

**Estimativa:** 1 story point (~0,5 hora)

## Considerações Técnicas

- Dependências: nenhuma.
- Impactos: apenas visual/UX, nenhuma mudança de comportamento ou dados.
- Riscos: baixíssimo. Validar specs de mobile-first/acessibilidade existentes
  (`accessibility_spec`, `mobile_first_spec`) caso verifiquem classes desses botões — não devem
  quebrar, mas podem precisar de atualização se usarem matching exato de classes.

## Checklist de Implementação

- [ ] Adicionar `cursor-pointer` na classe do `link_to` de "Lançar horas" (`_task_row.html.erb:28`)
- [ ] Adicionar `cursor-pointer` na classe do `button_to` de "Entregar tarefa" (`_task_row.html.erb:40`)
- [ ] Adicionar `title:` no `link_to` de "Lançar horas"
- [ ] Adicionar `title:` no `button_to` de "Entregar tarefa"
- [ ] Rodar specs de accessibility/mobile-first relacionados ao dashboard
- [ ] Validar manualmente via Playwright/dashboard real (hover mostra mãozinha + tooltip)
