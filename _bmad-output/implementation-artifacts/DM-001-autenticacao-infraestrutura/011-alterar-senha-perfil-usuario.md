# Story 1.11: Alterar Senha — Página de Perfil do Usuário

**Status:** done
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

- [x] **AC1 — Link no menu:** link "Minha Conta" aparece no menu de navegação (desktop e mobile), entre "Tarefas" e o botão "Sair"
- [x] **AC2 — Página de perfil:** `GET /profile` exibe formulário com dois campos: "Nova senha" e "Confirmar nova senha"
- [x] **AC3 — Sem senha atual:** o formulário não exige a senha atual — apenas nova senha + confirmação
- [x] **AC4 — Validação de confirmação:** se as senhas não coincidirem, exibe mensagem de erro na página (sem redirecionar)
- [x] **AC5 — Senha mínima:** validar mínimo de 8 caracteres (padrão `has_secure_password`)
- [x] **AC6 — Sucesso:** após alterar, redireciona para o dashboard com flash notice "Senha alterada com sucesso"
- [x] **AC7 — Protegido:** a rota `/profile` requer autenticação — redireciona para login se não autenticado

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

- [x] `spec/requests/profiles_spec.rb`:
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

---

## File List

- `config/routes.rb` — adicionado `resource :profile, only: [:show, :update]`
- `app/controllers/profiles_controller.rb` — criado (novo)
- `app/views/profiles/show.html.erb` — criado (novo)
- `app/views/layouts/application.html.erb` — link "Minha Conta" no desktop e mobile
- `app/models/user.rb` — adicionado `validates :password, length: { minimum: 8 }, allow_nil: true`
- `spec/requests/profiles_spec.rb` — criado (novo) — 11 exemplos, 0 falhas
- `config/locales/pt-BR.yml` — adicionado `too_short`, `confirmation`, `password_confirmation`
- `spec/requests/accessibility_spec.rb` — cobertura para GET /profile (h1, labels, aria-describedby, role=alert)
- `spec/requests/mobile_first_spec.rb` — cobertura para GET /profile (wrapper, campos, botão)
- `spec/requests/authentication_spec.rb` — spec link "Minha Conta" no navbar

---

## Dev Agent Record

### Implementation Notes

- **Decisão:** `validates :password, length: { minimum: 8 }, allow_nil: true` adicionado ao User model. O `has_secure_password` no Rails 8 não impõe tamanho mínimo por padrão — `allow_nil: true` preserva a atualização de outros atributos sem requerer senha.
- **Decisão:** `profile_params` extraído em método privado no controller (strong parameters).
- **Decisão:** View segue padrão visual Tailwind dark do projeto (gray-800/700, blue-600).
- Link no menu desktop inserido após "Tarefas", antes do bloco "User Menu (Desktop)".
- Link no menu mobile inserido após "Tarefas", antes do bloco de email/logout.

### Test Results

- `spec/requests/profiles_spec.rb`: 10 exemplos, 0 falhas ✅
- Suite completa (request specs relevantes): 112 exemplos, 0 falhas ✅

### Change Log

- 2026-05-04: Implementação completa da Story 1.11 — ProfilesController, view, rota, link no menu desktop/mobile, validação de senha mínima no User model, 10 specs passando.
- 2026-05-04: Ajustes QA — traduções pt-BR (too_short, confirmation, password_confirmation), specs com mensagens específicas, cobertura em accessibility_spec/mobile_first_spec/authentication_spec, 100 specs passando (0 regressões).
