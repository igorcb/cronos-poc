# Story 1.10: Aplicar Padrão de Campos Obrigatórios com Asterisco nos Formulários

**Status:** done
**Domínio:** DM-001-autenticacao-infraestrutura
**Data:** 2026-04-21
**Epic:** Epic 1 — Autenticação & Infraestrutura (UI Base)
**Story ID:** 1.10
**Story Key:** 1-10-aplicar-padrao-campos-obrigatorios-asterisco-formularios

---

## Story

**Como** Igor (usuário do sistema),
**Quero** ver asteriscos vermelhos nos campos obrigatórios, validação client-side sem popover nativo, e borda vermelha nos campos com erro,
**Para que** eu tenha feedback visual claro antes e depois de submeter o formulário.

---

## Contexto Técnico

### Três melhorias aprovadas (padrão final)

1. **Asterisco vermelho no label** — indica campo obrigatório antes de submeter
2. **Validação client-side sem backend** — Stimulus controller impede submit com campos vazios, sem popover nativo do browser
3. **Borda vermelha no campo com erro** — quando servidor retorna erro, o campo recebe `border-red-500` em vez de `border-gray-600`

### Escopo
- `app/views/companies/_form.html.erb` — **JÁ tem o asterisco**, mas ainda falta a validação client-side e a borda vermelha
- `app/views/projects/_form.html.erb` — precisa das 3 melhorias
- `app/views/tasks/_form.html.erb` — precisa das 3 melhorias

---

## Melhoria 1 — Asterisco vermelho no label

### Padrão de label (igual ao aprovado em companies)
```erb
<%= form.label :name, class: "block text-sm font-medium text-gray-300 mb-1" do %>
  Nome da Tarefa
  <span class="text-red-400 ml-1" aria-hidden="true">*</span>
<% end %>
```

### Nota de rodapé (antes dos botões)
```erb
<p class="text-xs text-gray-400"><span class="text-red-400">*</span> campos obrigatórios</p>
```

### Remover `required: true` de todos os campos obrigatórios
— elimina o popover nativo do browser. Manter `aria-required: "true"`.

---

## Melhoria 2 — Validação client-side com Stimulus (sem JS nativo)

### Abordagem
- `novalidate` no form — desativa validação HTML5 nativa do browser
- Stimulus controller `form-validation` — intercepta o submit e verifica campos `aria-required="true"` vazios
- Se vazio: foca no primeiro campo inválido e exibe mensagem inline, **não submete**
- Se tudo preenchido: submete normalmente ao servidor

### Controller Stimulus — `app/javascript/controllers/form_validation_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const required = this.element.querySelectorAll("[aria-required='true']")
    let firstInvalid = null

    required.forEach(field => {
      if (!field.value || field.value.trim() === "") {
        field.classList.add("border-red-500")
        field.classList.remove("border-gray-600")
        if (!firstInvalid) firstInvalid = field
      }
    })

    if (firstInvalid) {
      event.preventDefault()
      firstInvalid.focus()
    }
  }

  clearError(event) {
    const field = event.target
    if (field.value && field.value.trim() !== "") {
      field.classList.remove("border-red-500")
      field.classList.add("border-gray-600")
    }
  }
}
```

### Registrar o controller em `app/javascript/controllers/index.js`
```javascript
import FormValidationController from "./form_validation_controller"
application.register("form-validation", FormValidationController)
```

### Usar nos forms

> **IMPORTANTE:** NÃO usar `action: "submit->form-validation#submit"` no data do form.
> Turbo captura o submit antes do Stimulus action system — o controller usa `connect()`/`disconnect()`
> com `addEventListener("submit", ..., { capture: true })` para interceptar antes do Turbo.

```erb
<%= form_with(model: company, class: "space-y-6",
    data: { controller: "form-validation" },
    novalidate: true) do |form| %>
```

Para limpar a borda ao digitar, adicionar em cada campo obrigatório:
```erb
data: { action: "input->form-validation#clearError" }
```

---

## Melhoria 3 — Borda vermelha no campo com erro (server-side)

Quando o servidor retorna erro de validação, o campo deve ter `border-red-500` em vez de `border-gray-600`.

### Padrão de classe condicional no input

> **IMPORTANTE:** incluir a classe `border` base — sem ela `border-red-500` não tem efeito visual
> (`border-width` fica `0px` e a cor não aparece).

```erb
class: "mt-1 block w-full min-h-[44px] rounded-md bg-gray-700 text-white shadow-sm
        focus:border-blue-500 focus:ring-blue-500 px-3 py-2
        border #{company.errors[:name].any? ? 'border-red-500' : 'border-gray-600'}"
```

---

## Campos por formulário

### companies/_form.html.erb (atualizar apenas melhorias 2 e 3)
| Campo | Asterisco | Client validation | Borda vermelha |
|-------|-----------|-------------------|----------------|
| `:name` | ✅ já tem | adicionar | adicionar |
| `:hourly_rate` | ✅ já tem | adicionar | adicionar |

### projects/_form.html.erb (todas as 3 melhorias)
| Campo | Obrigatório | Obs |
|-------|-------------|-----|
| `:name` | ✅ sim | |
| `:company_id` | ✅ sim | label usa `id: "company-label"` — manter |

### tasks/_form.html.erb (todas as 3 melhorias)
| Campo | Obrigatório | Obs |
|-------|-------------|-----|
| `:name` | ✅ sim | |
| `:company_id` | ✅ sim | |
| `:project_id` | ✅ sim | `disabled: true` e `project_selector_target` — não remover |
| `:start_date` | ✅ sim | |
| `:estimated_hours` | ✅ sim | |
| `:notes` | ❌ opcional | sem asterisco, sem validação client |

---

## Acceptance Criteria

### Asterisco (Melhoria 1)
- [x] AC1: `projects/_form` — labels com `*` vermelho nos campos obrigatórios
- [x] AC2: `projects/_form` — nota `* campos obrigatórios` antes dos botões
- [x] AC3: `tasks/_form` — labels com `*` vermelho nos 5 campos obrigatórios
- [x] AC4: `tasks/_form` — "Observações" **sem** asterisco
- [x] AC5: `tasks/_form` — nota `* campos obrigatórios` antes dos botões
- [x] AC6: `required: true` removido de todos os campos obrigatórios nos 3 forms

### Validação client-side (Melhoria 2)
- [x] AC7: Submeter form vazio **não bate no backend** — Stimulus intercepta
- [x] AC8: Primeiro campo vazio recebe foco automaticamente
- [x] AC9: Campo vazio recebe `border-red-500` ao tentar submeter
- [x] AC10: Ao preencher campo com erro, borda volta para `border-gray-600`
- [x] AC11: `novalidate` nos 3 forms — sem popover nativo do browser

### Borda vermelha server-side (Melhoria 3)
- [x] AC12: Campos com erro retornado pelo servidor têm `border-red-500`
- [x] AC13: Campos sem erro têm `border-gray-600`

### Regressão
- [x] AC14: Testes existentes passando sem regressão

---

## Guardrails

- **NÃO** usar `required: true` HTML — já removido, não re-adicionar
- **NÃO** remover `aria-required: "true"` — usado pelo Stimulus para detectar campos obrigatórios
- **NÃO** remover `data:`, `disabled:`, `aria-labelledby:` ou outros atributos existentes
- **NÃO** alterar lógica de erros server-side — blocos `if errors.any?` e `span id="*_error"` intocados
- **NÃO** alterar campos opcionais (`:notes` em tasks)
- **O Stimulus controller `project-selector`** em tasks já existe — o novo `form-validation` é adicional, usar `data: { controller: "project-selector form-validation" }`

---

## Dev Agent Record

### Checklist de Implementação
- [x] Stimulus controller `form_validation_controller.js` criado
- [x] Controller registrado em `index.js`
- [x] `companies/_form.html.erb` — melhorias 2 e 3 aplicadas
- [x] `projects/_form.html.erb` — melhorias 1, 2 e 3 aplicadas
- [x] `tasks/_form.html.erb` — melhorias 1, 2 e 3 aplicadas
- [x] Testes passando sem regressão

### Notas de Implementação
- Stimulus controller usa `connect()`/`disconnect()` com `addEventListener("submit", ..., { capture: true })` para interceptar antes do Turbo — conforme especificado na story.
- `companies/_form` já tinha asteriscos; aplicadas melhorias 2 (novalidate + form-validation controller) e 3 (borda condicional border-red-500/border-gray-600).
- `projects/_form` e `tasks/_form` receberam as 3 melhorias completas.
- Em tasks, `data: { controller: "project-selector form-validation" }` — ambos controllers ativos sem conflito.
- Campo `company_id` em tasks manteve `change->project-selector#loadProjects` e adicionou `change->form-validation#clearError`.
- Campo `:notes` em tasks permanece opcional (sem asterisco, sem aria-required, sem validação client-side).
- Suite completa: 583 examples, 0 failures, 1 pending (pending pré-existente, não relacionado).

### Arquivos Modificados
- `app/javascript/controllers/form_validation_controller.js` (novo)
- `app/javascript/controllers/index.js`
- `app/views/companies/_form.html.erb`
- `app/views/projects/_form.html.erb`
- `app/views/tasks/_form.html.erb`
