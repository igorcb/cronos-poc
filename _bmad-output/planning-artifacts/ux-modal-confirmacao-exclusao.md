# UX Spec — Modal de Confirmação de Exclusão (substituir confirm() nativo)

**Autor:** Sally (UX) · **Data:** 2026-07-03 · **Solicitante:** Igor
**Escopo:** Estético apenas. Sem soft-delete, sem undo, sem mudança de comportamento.

---

## Problema

A exclusão de tarefas (e outros recursos) dispara o `confirm()` nativo do
browser via `data-turbo-confirm` — um modal cinza sem estilo que quebra a
identidade visual do Cronos. Dor puramente estética (a "Maria"), não
comportamental.

## Solução

Substituir o diálogo nativo do Turbo por um modal custom que reaproveita o
padrão visual já existente em `tasks/new` (`role="dialog"`, `aria-modal`,
`data-controller="modal"`). Um único `Turbo.setConfirmMethod()` global
intercepta **todos** os `data-turbo-confirm` do app.

### Isto é um PADRÃO DEFAULT do app — não uma tela

O `Turbo.setConfirmMethod()` é registrado **uma vez, globalmente**. A partir
daí, **qualquer tela — presente ou futura** — que use `data-turbo-confirm`
dispara o modal estilizado automaticamente, sem código extra por tela. O
objetivo desta mudança é justamente **evitar que telas novas voltem a cair no
`confirm()` nativo cinza**.

**Convenção a partir daqui (regra do projeto):**
1. Para confirmar ações destrutivas, use `data-turbo-confirm="mensagem"`.
   O modal estilizado é o comportamento padrão — automático.
2. **NUNCA** use `confirm()` nativo do browser nem crie modal de confirmação
   ad-hoc por tela — quebra o padrão e a acessibilidade herdada.
3. Toda confirmação herda de graça: `role="dialog"`, `aria-modal`, foco inicial
   no Cancelar, ESC/backdrop fecham, focus trap e restauração de foco.

### Cobertura (todos já usam `data-turbo-confirm` hoje)

| Local | Arquivo | Mensagem atual |
|---|---|---|
| Excluir tarefa | `app/components/task_card_component.html.erb:34` | Tem certeza que deseja remover "…"? |
| Remover lançamento | `app/views/task_items/_list.html.erb:33` | Tem certeza que deseja remover este lançamento? |
| Deletar projeto | `app/views/projects/index.html.erb:27` | Tem certeza que deseja deletar este projeto? |
| Desativar empresa | `app/views/companies/index.html.erb:28` | Tem certeza que deseja desativar esta empresa? |

> O texto de cada `turbo_confirm` continua sendo a fonte da verdade da mensagem
> — o modal apenas o renderiza com estilo. Nada muda nas views além do visual.

---

## Design do Modal

**Estrutura visual** (espelha `tasks/new`):
- Backdrop: `fixed inset-0 z-50 flex items-center justify-center bg-black/50`
- Card: `bg-gray-800 shadow-2xl rounded-xl ring-1 ring-gray-600 p-4 sm:p-6`,
  largura `sm:max-w-md mx-4` (menor que o de formulário — é só confirmação)

**Conteúdo** (rótulos GENÉRICOS — o modal é global e serve exclusão,
desativação, etc.; a especificidade vem da mensagem do `turbo_confirm`):
- **Título** (`#confirm-dialog-title`, `text-xl font-bold text-white`):
  `Confirmar ação`
- **Corpo** (`text-gray-300`): a mensagem do `turbo_confirm` (contextual,
  ex.: "Tem certeza que deseja desativar esta empresa?") +
  linha de aviso `Esta ação não pode ser desfeita.`
- **Ações** (rodapé, alinhado à direita, gap):
  - `Cancelar` — secundário/neutro:
    `bg-gray-700 hover:bg-gray-600 text-white`
  - `Confirmar` — destrutivo vermelho sólido (opção A):
    `bg-red-600 hover:bg-red-700 text-white`

> **Nota (aprendizado da validação):** rótulos fixos "Excluir tarefa?"/"Excluir"
> ficam incorretos em telas que desativam/deletam outros recursos. Como é um
> modal global, título e botão de ação devem ser genéricos.

**Acessibilidade** (obrigatório — segue padrão do projeto):
- `role="dialog"` + `aria-modal="true"` + `aria-labelledby="modal-title"`
- **Foco inicial no botão `Cancelar`** (opção segura)
- Foco preso dentro do modal (focus trap); ao fechar, retorna ao gatilho
- **ESC** fecha (= Cancelar) · **clique no backdrop** fecha (= Cancelar)
- Todos os alvos de toque `min-h-[44px]` (mobile-first, como o resto do app)

---

## Comportamento

1. Usuário clica no gatilho com `data-turbo-confirm` (ex.: lixeira da tarefa).
2. Turbo chama o método custom → sobe o modal com a mensagem do atributo.
3. `Cancelar` / ESC / backdrop → promise resolve `false`, nada acontece.
4. `Excluir` → promise resolve `true`, Turbo prossegue com o DELETE normal.

Fluxo de rede, controllers e streams **inalterados** — a confirmação é 100%
client-side, só troca a camada visual.

---

## Fora de escopo (confirmado com Igor)

- ❌ Soft-delete / lixeira / recuperação
- ❌ Toast "Desfazer" (undo)
- ❌ Qualquer mudança no backend ou nos controllers

---

## Notas para implementação (Amelia)

- Ponto único de troca: `Turbo.setConfirmMethod(...)` no entrypoint JS,
  resolvendo uma Promise a partir do modal Stimulus.
- Reaproveitar `modal_controller.js` ou criar um `confirm_controller.js`
  irmão — decisão de implementação, ambos aceitáveis desde que mantenham
  focus trap + restauração de foco.
- Cobertura de specs: adicionar cenário nos specs transversais de
  acessibilidade e mobile-first (nova view/parcial de modal), conforme
  convenção do projeto. Verificar `role="dialog"`, `aria-modal`,
  botão destrutivo e foco inicial no Cancelar.
