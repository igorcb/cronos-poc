# Story 1.11: Alterar Senha — Página de Perfil do Usuário

**Status:** ready-for-dev
**Domínio:** DM-001-autenticacao-infraestrutura
**Data:** 2026-05-04
**Epic:** Epic 1 — Autenticação & Infraestrutura
**Story ID:** 1.11
**Story Key:** 1-11-alterar-senha-perfil-usuario

---

## Contexto

O sistema é single-user e já possui infraestrutura de reset de senha via email (`PasswordsController`, `PasswordsMailer`), mas o usuário não quer depender de email para trocar a senha. É necessária uma forma direta de alterar a senha dentro do sistema (já autenticado), acessível pelo menu de navegação.

Não é necessário informar a senha atual — basta nova senha + confirmação.

---

## História do Usuário

**Como** usuário autenticado no Cronos POC,
**Quero** acessar uma página "Minha Conta" pelo menu de navegação e alterar minha senha diretamente,
**Para** conseguir trocar a senha sem depender de email ou token externo.

---

## Critérios de Aceite

- [ ] **AC1 — Link no menu:** link "Minha Conta" aparece no menu de navegação (desktop e mobile), entre "Tarefas" e o botão "Sair"
- [ ] **AC2 — Página de perfil:** `GET /profile` exibe formulário com dois campos: "Nova senha" e "Confirmar nova senha"
- [ ] **AC3 — Sem senha atual:** o formulário não exige a senha atual — apenas nova senha + confirmação
- [ ] **AC4 — Validação de confirmação:** se as senhas não coincidirem, exibe mensagem de erro na página (sem redirecionar)
- [ ] **AC5 — Senha mínima:** validar mínimo de 8 caracteres (padrão `has_secure_password`)
- [ ] **AC6 — Sucesso:** após alterar, redireciona para o dashboard com flash notice "Senha alterada com sucesso"
- [ ] **AC7 — Protegido:** a rota `/profile` requer autenticação — redireciona para login se não autenticado

---

## Análise Técnica

### Rota

```ruby
# config/routes.rb
resource :profile, only: [:show, :update]
```

### Controller

```ruby
# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  def show
  end

  def update
    if Current.user.update(params.permit(:password, :password_confirmation))
      redirect_to root_path, notice: "Senha alterada com sucesso."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
```

### View `profiles/show.html.erb`

Formulário simples com dois campos:

```erb
<%= form_with url: profile_path, method: :patch do |f| %>
  <%= f.label :password, "Nova senha" %>
  <%= f.password_field :password, autocomplete: "new-password" %>

  <%= f.label :password_confirmation, "Confirmar nova senha" %>
  <%= f.password_field :password_confirmation, autocomplete: "new-password" %>

  <%= f.submit "Alterar senha" %>
<% end %>
```

### Menu de navegação (`layouts/application.html.erb`)

Adicionar em desktop e mobile, antes do botão "Sair":

```erb
<%= link_to "Minha Conta", profile_path, class: "text-gray-300 hover:text-blue-400 px-3 py-2 rounded-md text-sm font-medium" %>
```

### Observação sobre `Current.user`

O Rails 8 Authentication usa `Current.user` (definido via `before_action :resume_session`). O update de senha usa `has_secure_password` — basta atribuir `:password` e `:password_confirmation`.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Adicionar `resource :profile, only: [:show, :update]` |
| `app/controllers/profiles_controller.rb` | Criar controller com actions `show` e `update` |
| `app/views/profiles/show.html.erb` | Criar formulário de alteração de senha |
| `app/views/layouts/application.html.erb` | Adicionar link "Minha Conta" no menu (desktop e mobile) |

---

## Testes

- [ ] `spec/requests/profiles_spec.rb`:
  - GET `/profile` → 200 quando autenticado
  - GET `/profile` → redirect para login quando não autenticado
  - PATCH `/profile` com senhas válidas → redirect para root com notice
  - PATCH `/profile` com senhas diferentes → 422 com erro na view
  - PATCH `/profile` com senha < 8 chars → 422 com erro na view

---

## Dependências

- `has_secure_password` no model User — **já presente**
- `Current.user` via Rails 8 Authentication — **já presente**
- Menu de navegação em `layouts/application.html.erb` — **já existe**

---

## Estimativa

**1 story point** (~2h) — controller simples, view mínima, ajuste no layout.
