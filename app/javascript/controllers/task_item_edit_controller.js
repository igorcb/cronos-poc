import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  load(event) {
    const btn = event.currentTarget
    const form = this.element.querySelector("form")
    if (!form) return

    const start = btn.dataset.taskItemEditStartParam
    const end   = btn.dataset.taskItemEditEndParam
    const date  = btn.dataset.taskItemEditDateParam
    const status = btn.dataset.taskItemEditStatusParam
    const url   = btn.dataset.taskItemEditUrlParam

    form.querySelector("input[name$='[start_time]']").value = start
    form.querySelector("input[name$='[end_time]']").value = end
    form.querySelector("input[name$='[work_date]']").value = date
    form.querySelector("select[name$='[status]']").value = status

    form.action = url
    form.querySelector("input[name='_method']")?.remove()
    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "patch"
    form.prepend(methodInput)

    const submitBtn = form.querySelector("[type='submit']")
    if (submitBtn) submitBtn.value = "Salvar Alterações"

    form.querySelector("input[name$='[start_time]']").dispatchEvent(new Event("change"))
    form.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }
}
