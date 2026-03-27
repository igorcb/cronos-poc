# Story 7.3: Criar Testes de System para Fluxo Completo

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** testes end-to-end do fluxo de CRUD,
**Para que** funcionalidade completa seja garantida.

## Acceptance Criteria

1. Teste simula: login → criar empresa → criar projeto → criar entrada → editar entrada → deletar entrada
2. Teste confirma validações client-side funcionam
3. Teste confirma totalizadores atualizam
4. Teste confirma fluxo completo funciona sem erros
5. `bundle exec rspec spec/system/time_entries_spec.rb` passa 100%

## Dev Notes

```ruby
# spec/system/time_entries_spec.rb
require 'rails_helper'

RSpec.describe "TimeEntries", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:user) { create(:user) }

  it "completes full CRUD flow" do
    # Login
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Login"

    # Criar empresa
    visit new_company_path
    fill_in "Nome", with: "Empresa Teste"
    fill_in "Taxa R$/hora", with: "150.00"
    click_button "Salvar"
    expect(page).to have_content("Empresa cadastrada com sucesso")

    # Criar projeto
    visit new_project_path
    fill_in "Nome do Projeto", with: "Projeto X"
    select "Empresa Teste", from: "Empresa"
    click_button "Salvar"

    # Criar entrada
    visit new_time_entry_path
    select "Empresa Teste", from: "Empresa"
    select "Projeto X", from: "Projeto"
    fill_in "Data", with: Date.today
    fill_in "Início", with: "09:00"
    fill_in "Fim", with: "17:00"
    fill_in "Atividade", with: "Desenvolvimento"
    click_button "Salvar"

    expect(page).to have_content("Entrada registrada com sucesso")
    expect(page).to have_content("Empresa Teste")

    # Editar entrada
    click_link "Editar"
    fill_in "Fim", with: "18:00"
    click_button "Salvar"
    expect(page).to have_content("Entrada atualizada com sucesso")

    # Deletar entrada
    click_button "Deletar"
    expect(page).to have_content("Entrada deletada com sucesso")
  end
end
```
