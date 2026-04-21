# Story 1.9: Adicionar "Tarefas" ao Menu de Navegação

**Status:** ready-for-dev
**Domínio:** DM-001-autenticacao-infraestrutura
**Data:** 2026-04-21
**Epic:** Epic 1 — Autenticação & Infraestrutura (UI Base)
**Story ID:** 1.9
**Story Key:** 1-9-adicionar-tarefas-ao-menu-de-navegacao

---

## Story

**Como** Igor (usuário do sistema),
**Quero** ver "Tarefas" no menu de navegação,
**Para que** eu possa acessar a listagem de tarefas diretamente da navbar sem precisar navegar via dashboard.

---

## Contexto Técnico

### Arquivo a modificar
- `app/views/layouts/application.html.erb`

### Menu desktop (linha ~43-47)
```erb
<div class="hidden md:flex items-center space-x-4">
  <%= link_to "Dashboard", root_path, ... %>
  <%= link_to "Empresas", companies_path, ... %>
  <%= link_to "Projetos", projects_path, ... %>
  <!-- ADICIONAR: Tarefas -->
</div>
```

### Menu mobile (linha ~82-85)
```erb
<div class="px-2 pt-2 pb-3 space-y-1 border-t border-gray-700">
  <%= link_to "Dashboard", root_path, ... %>
  <%= link_to "Empresas", companies_path, ... %>
  <%= link_to "Projetos", projects_path, ... %>
  <!-- ADICIONAR: Tarefas -->
</div>
```

### Classes CSS a usar (mesmas dos links existentes)
- Desktop: `"text-gray-300 hover:text-blue-400 px-3 py-2 rounded-md text-sm font-medium"`
- Mobile: `"block text-gray-300 hover:text-blue-400 hover:bg-gray-700 px-3 py-2 rounded-md text-base font-medium"`

### Rota
```ruby
tasks_path  # GET /tasks
```

---

## Acceptance Criteria

- [ ] AC1: Link "Tarefas" aparece no menu desktop entre "Projetos" e o User Menu
- [ ] AC2: Link "Tarefas" aparece no menu mobile entre "Projetos" e a seção de usuário
- [ ] AC3: Link aponta para `tasks_path` (`/tasks`)
- [ ] AC4: Estilo visual idêntico aos demais links do menu (mesmas classes CSS)
- [ ] AC5: Link visível apenas quando autenticado (já garantido pelo `if authenticated?` que envolve toda a navbar)

---

## Dev Notes

### Mudança cirúrgica — apenas 2 adições no mesmo arquivo

**Desktop** — inserir após o link de Projetos:
```erb
<%= link_to "Tarefas", tasks_path, class: "text-gray-300 hover:text-blue-400 px-3 py-2 rounded-md text-sm font-medium" %>
```

**Mobile** — inserir após o link de Projetos no mobile-menu:
```erb
<%= link_to "Tarefas", tasks_path, class: "block text-gray-300 hover:text-blue-400 hover:bg-gray-700 px-3 py-2 rounded-md text-base font-medium" %>
```

### Rodar após implementação
```bash
docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec spec/system/tasks_spec.rb --format documentation
```

---

## Guardrails

- **NÃO** alterar a ordem dos links existentes (Dashboard, Empresas, Projetos)
- **NÃO** modificar nada fora do bloco de links nav (não tocar no User Menu, no botão mobile, etc.)
- **SEMPRE** adicionar em ambos os menus: desktop E mobile

---

## Dev Agent Record

### Checklist de Implementação
- [ ] Link "Tarefas" adicionado no menu desktop
- [ ] Link "Tarefas" adicionado no menu mobile
- [ ] Estilo consistente com links existentes
- [ ] Rota correta (`tasks_path`)

### Notas de Implementação
_(Preencher pelo dev agent)_
