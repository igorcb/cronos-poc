// Padrão global de confirmação de ação destrutiva.
//
// Substitui o confirm() nativo do browser por um modal estilizado, consistente
// com a identidade visual do app (padrão de tasks/new). Registrado UMA vez,
// globalmente: toda tela — presente ou futura — que use `data-turbo-confirm`
// dispara este modal automaticamente. NUNCA usar confirm() nativo nem modal
// ad-hoc por tela.
//
// Escopo: estético. Não altera comportamento de exclusão — apenas a UI da
// confirmação. A promise resolve `true` (Excluir) → Turbo prossegue com o
// DELETE; `false` (Cancelar / ESC / backdrop) → nada acontece.

import { Turbo } from "@hotwired/turbo-rails"

function buildDialog(message) {
  const overlay = document.createElement("div")
  overlay.className =
    "fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto p-4"
  overlay.setAttribute("role", "dialog")
  overlay.setAttribute("aria-modal", "true")
  overlay.setAttribute("aria-labelledby", "confirm-dialog-title")

  overlay.innerHTML = `
    <div class="relative w-full sm:max-w-md mx-auto">
      <div class="bg-gray-800 shadow-2xl rounded-xl ring-1 ring-gray-600 p-6">
        <h2 id="confirm-dialog-title" class="text-xl font-bold text-white mb-2">
          Confirmar ação
        </h2>
        <p class="text-gray-300 mb-6">
          ${message}<br>
          <span class="text-gray-400 text-sm">Esta ação não pode ser desfeita.</span>
        </p>
        <div class="flex flex-col-reverse sm:flex-row sm:justify-end gap-3">
          <button type="button" data-confirm-cancel
            class="min-h-[44px] px-4 py-2 rounded-md bg-gray-700 hover:bg-gray-600 text-white transition focus:outline-none focus:ring-2 focus:ring-gray-400">
            Cancelar
          </button>
          <button type="button" data-confirm-accept
            class="min-h-[44px] px-4 py-2 rounded-md bg-red-600 hover:bg-red-700 text-white font-medium transition focus:outline-none focus:ring-2 focus:ring-red-400">
            Confirmar
          </button>
        </div>
      </div>
    </div>
  `
  return overlay
}

function customConfirm(message) {
  return new Promise((resolve) => {
    const triggerElement = document.activeElement
    const overlay = buildDialog(message)
    document.body.appendChild(overlay)

    const cancelBtn = overlay.querySelector("[data-confirm-cancel]")
    const acceptBtn = overlay.querySelector("[data-confirm-accept]")

    // Foco preso dentro do modal (focus trap simples entre os dois botões).
    const focusables = [cancelBtn, acceptBtn]
    function trap(event) {
      if (event.key !== "Tab") return
      const first = focusables[0]
      const last = focusables[focusables.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    function cleanup(result) {
      document.removeEventListener("keydown", onKeydown)
      overlay.remove()
      if (triggerElement && typeof triggerElement.focus === "function") {
        triggerElement.focus() // restaura foco ao gatilho
      }
      resolve(result)
    }

    function onKeydown(event) {
      if (event.key === "Escape") {
        event.preventDefault()
        cleanup(false)
      } else {
        trap(event)
      }
    }

    cancelBtn.addEventListener("click", () => cleanup(false))
    acceptBtn.addEventListener("click", () => cleanup(true))
    overlay.addEventListener("click", (event) => {
      if (event.target === overlay) cleanup(false) // clique no backdrop = cancelar
    })

    document.addEventListener("keydown", onKeydown)

    // Foco inicial no Cancelar (opção segura).
    cancelBtn.focus()
  })
}

// Turbo 8: a API oficial é `Turbo.config.forms.confirm`.
// `Turbo.setConfirmMethod` está deprecated e será removido.
Turbo.config.forms.confirm = customConfirm
