require "rails_helper"

RSpec.describe "Tasks", type: :system do
  let(:user) { create(:user) }
  let(:company) { create(:company) }
  let(:project) { create(:project, company: company) }

  before do
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Senha", with: "Password123!"
    click_button "Entrar"
  end

  describe "index" do
    context "with existing tasks" do
      let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

      it "displays tasks list with Ações column" do
        visit tasks_path
        expect(page).to have_css("th", text: "Ações")
        expect(page).to have_content(task.name)
      end

      it "shows Editar and Excluir links for each task" do
        visit tasks_path
        expect(page).to have_link("Editar", href: edit_task_path(task))
        expect(page).to have_css("a[aria-label='Excluir tarefa #{task.display_name}']")
      end
    end

    it "shows empty state when no tasks exist" do
      visit tasks_path
      expect(page).to have_content("Nenhuma tarefa encontrada")
    end
  end

  describe "edit" do
    let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

    it "navigates to edit form via Editar link" do
      # Link usa data-turbo-frame: _top — rack_test segue o href diretamente
      visit tasks_path
      # Verificar que o link existe e apontar para o path correto
      expect(page).to have_link("Editar", href: edit_task_path(task))
      # Navegar diretamente (rack_test não processa data-turbo-frame)
      visit edit_task_path(task)
      expect(current_path).to eq(edit_task_path(task))
      expect(page).to have_field("Nome da Tarefa", with: task.name)
    end

    it "updates task and shows flash message" do
      visit edit_task_path(task)
      fill_in "Nome da Tarefa", with: "Nome atualizado pelo sistema"
      click_button "Salvar Alterações"
      expect(page).to have_content("Tarefa atualizada com sucesso")
      expect(task.reload.name).to eq("Nome atualizado pelo sistema")
    end

    it "shows validation errors when name is blank" do
      visit edit_task_path(task)
      fill_in "Nome da Tarefa", with: ""
      click_button "Salvar Alterações"
      expect(page).to have_content("erro")
    end
  end

  describe "destroy" do
    let!(:task) { create(:task, start_date: Date.current, company: company, project: project) }

    it "removes task when DELETE request is made" do
      # turbo_confirm requer JS — testamos o comportamento via DELETE direto
      visit tasks_path
      expect(page).to have_content(task.name)
      # Verificar que o link de excluir existe com aria-label correto
      expect(page).to have_css("a[aria-label='Excluir tarefa #{task.display_name}']")
      # Executar destroy via driver rack_test
      page.driver.delete task_path(task)
      expect(Task.find_by(id: task.id)).to be_nil
    end

    it "shows Excluir link with correct aria-label" do
      visit tasks_path
      expect(page).to have_css(
        "a[aria-label='Excluir tarefa #{task.display_name}'][data-turbo-method='delete']"
      )
    end
  end
end
