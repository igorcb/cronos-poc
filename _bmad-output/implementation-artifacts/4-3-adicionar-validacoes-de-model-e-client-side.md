# Story 4.3: Adicionar Validações de Model e Client-Side

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** validações que impeçam dados incorretos,
**Para que** eu não registre entradas inválidas.

## Acceptance Criteria

1. Valida presence de: date, start_time, end_time, activity, status
2. Valida inclusion de status: %w[pending completed reopened delivered]
3. Validação customizada: end_time > start_time
4. Validação customizada: project.company_id == company_id
5. Crio Stimulus controller `form_validation_controller.js`
6. Validação client-side confirma end_time > start_time antes de submit
7. Mensagens de erro são exibidas em tempo real

## Dev Notes

### Stimulus Controller

```javascript
// app/javascript/controllers/form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startTime", "endTime", "errorMessage"]

  validateTimes() {
    const start = this.startTimeTarget.value
    const end = this.endTimeTarget.value

    if (start && end && end <= start) {
      this.showError("Horário final deve ser posterior ao inicial")
      this.endTimeTarget.setCustomValidity("Invalid")
      return false
    } else {
      this.hideError()
      this.endTimeTarget.setCustomValidity("")
      return true
    }
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorMessageTarget.classList.add("hidden")
  end
}
```

### Form Updates

```erb
<div data-controller="form-validation">
  <%= form.time_field :start_time,
      data: { form_validation_target: "startTime", action: "change->form-validation#validateTimes" } %>

  <%= form.time_field :end_time,
      data: { form_validation_target: "endTime", action: "change->form-validation#validateTimes" } %>

  <div data-form-validation-target="errorMessage" class="hidden text-red-600"></div>
</div>
```

## CRITICAL GUARDRAILS

- [ ] Tripla camada: DB Constraints + Model Validations + Client-side (ARQ17-ARQ20)
- [ ] Validação client-side NÃO substitui server-side
- [ ] Feedback visual imediato (< 500ms, NFR5)
