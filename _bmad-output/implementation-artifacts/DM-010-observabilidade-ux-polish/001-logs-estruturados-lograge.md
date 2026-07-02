# Story 11.1: Logs Estruturados com Lograge

**Status:** ready-for-dev
**Domínio:** DM-010-observabilidade-ux-polish
**Epic:** Epic 11 — Observabilidade & UX Polish
**Story ID:** 11.1
**Prioridade:** MEDIUM
**Estimativa:** 1 SP

---

## Contexto

Os logs atuais do Rails são verbosos e humanos: uma única request gera 10+ linhas (Started, Processing, queries SQL, Rendered, Completed). No Railway dashboard isso é difícil de filtrar e impossível de queryar.

Esta story instala **Lograge** para colapsar cada request em **uma linha JSON estruturada**, facilitando filtro, agregação e busca.

---

## História do Usuário

**Como** operador,
**Quero** logs estruturados em JSON com user_id, path, status, duration por request,
**Para** investigar incidentes filtrando por usuário/endpoint sem grep cego.

---

## Critérios de Aceite

### AC1 — Lograge instalado e ativo em produção
- [ ] **AC1.1:** Gem `lograge` adicionada ao Gemfile (group :production)
- [ ] **AC1.2:** Inicializer ou config em `production.rb` ativa `Lograge.enabled = true`
- [ ] **AC1.3:** Formatter: JSON (`Lograge::Formatters::Json.new`)
- [ ] **AC1.4:** Em development e test, Lograge **desativado** (não atrapalha debugging)

### AC2 — Payload mínimo útil
- [ ] **AC2.1:** Cada log de request inclui:
  - `method` (GET/POST/PATCH/DELETE)
  - `path` (rota requisitada)
  - `format` (html/turbo_stream/json)
  - `controller#action`
  - `status` (200/302/422/500...)
  - `duration` (em ms, total)
  - `db_runtime` e `view_runtime`
  - `user_id` (se autenticado; `nil` se não)
  - `ip` (remote_ip)
- [ ] **AC2.2:** Não incluir: params (vazaria senhas/tokens), headers completos

### AC3 — Custom data
- [ ] **AC3.1:** Override `ApplicationController#append_info_to_payload` para incluir `user_id` e `request_id`
- [ ] **AC3.2:** Lograge `custom_options` lê do payload e mescla no JSON

### AC4 — Cobertura
- [ ] **AC4.1:** Spec testa que payload customizado inclui user_id quando autenticado
- [ ] **AC4.2:** Spec testa user_id `nil` quando não autenticado

### AC5 — Validação em produção
- [ ] **AC5.1:** Após deploy, logs Railway mostram JSON em vez de linhas humanas
- [ ] **AC5.2:** Conseguir filtrar por `user_id=42` no dashboard Railway

---

## Análise Técnica

### Gemfile

```ruby
group :production do
  gem "lograge"
end
```

### config/environments/production.rb

```ruby
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
config.lograge.custom_options = lambda do |event|
  {
    user_id: event.payload[:user_id],
    request_id: event.payload[:request_id],
    ip: event.payload[:ip]
  }
end
```

### ApplicationController

```ruby
class ApplicationController < ActionController::Base
  # ... existente

  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
    payload[:request_id] = request.request_id
    payload[:ip] = request.remote_ip
  end
end
```

### Exemplo de output

**Antes:**
```
Started GET "/tasks" for 1.2.3.4 at 2026-05-26 10:00:00 +0000
Processing by TasksController#index as HTML
  User Load (0.5ms)  SELECT "users".* FROM "users" WHERE id = $1 LIMIT 1
  Task Load (2.3ms)  SELECT "tasks".* FROM "tasks" WHERE user_id = $1
Completed 200 OK in 18ms (Views: 12.5ms | ActiveRecord: 2.8ms)
```

**Depois:**
```json
{"method":"GET","path":"/tasks","format":"html","controller":"TasksController","action":"index","status":200,"duration":18.23,"view":12.5,"db":2.8,"user_id":42,"request_id":"abc-123","ip":"1.2.3.4"}
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Gemfile` | Adicionar `lograge` em :production |
| `config/environments/production.rb` | Habilitar Lograge + custom_options |
| `app/controllers/application_controller.rb` | `append_info_to_payload` |
| `spec/requests/lograge_payload_spec.rb` | Spec do payload customizado |

---

## Testes

- [ ] Payload customizado em request autenticada → user_id presente
- [ ] Payload em request não autenticada → user_id nil
- [ ] Suite 1.120+ specs continua passing

---

## Observações

- **Multi-tenancy útil para logs:** filtrar por `user_id` permite investigar bugs específicos sem ver dados de outros tenants
- **Não logar `params`:** já existe `parameter_filter` em Rails que mascara `password` etc, mas é simples vazar token por descuido. Melhor não incluir.
- **Próximo passo opcional (não nesta story):** enviar logs para serviço externo (Logtail, Better Stack) via syslog drain do Railway.
