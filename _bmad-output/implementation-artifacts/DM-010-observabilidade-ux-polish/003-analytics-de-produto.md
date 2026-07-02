# Story 11.3: Analytics de Produto (Plausible ou PostHog)

**Status:** ready-for-dev
**Domínio:** DM-010-observabilidade-ux-polish
**Epic:** Epic 11 — Observabilidade & UX Polish
**Story ID:** 11.3
**Prioridade:** HIGH
**Estimativa:** 2 SP

---

## Contexto

Com onboarding entregue (Story 9.3), o produto está pronto para receber novos usuários self-service. **Sem analytics não temos como saber:**

- Quantas pessoas chegam na tela de login?
- Quantas abandonam no Passo 1 do onboarding (criar Empresa)?
- Quantas chegam até criar a primeira Task (sucesso de ativação)?
- Quais features são usadas / ignoradas?
- Qual é o LTV / engagement dos usuários ativos?

Esta story instala um provider de analytics minimalista (Plausible ou PostHog) e adiciona tracking dos eventos críticos.

---

## História do Usuário

**Como** PM/operador do Cronos POC,
**Quero** medir drop-off no onboarding e uso de features,
**Para** priorizar melhorias com base em dados reais, não palpites.

---

## Critérios de Aceite

### AC1 — Escolha do provider
- [ ] **AC1.1:** Decisão entre Plausible ($9/mês cookie-less) e PostHog (free tier ~1M events)
- [ ] **AC1.2:** Decisão registrada em ADR na `architecture.md`
- [ ] **AC1.3:** Conta criada + site cadastrado + chave/script obtido

### AC2 — Script de tracking carregado
- [ ] **AC2.1:** Script do provider adicionado em `application.html.erb` (head)
- [ ] **AC2.2:** Carregado apenas em produção (`Rails.env.production?`)
- [ ] **AC2.3:** Defer/async para não bloquear render
- [ ] **AC2.4:** Sem cookies (Plausible) ou com banner consent (PostHog)

### AC3 — Eventos de pageview automáticos
- [ ] **AC3.1:** Todas as páginas geram pageview automaticamente
- [ ] **AC3.2:** Title da página é descritivo (já existe controle via `content_for :title`)

### AC4 — Eventos customizados de produto
- [ ] **AC4.1:** Evento `signup` — primeiro login bem-sucedido (User criado)
- [ ] **AC4.2:** Evento `onboarding_step_1_complete` — primeira Company criada
- [ ] **AC4.3:** Evento `onboarding_step_2_complete` — primeiro Project criado
- [ ] **AC4.4:** Evento `onboarding_complete` — primeira Task criada
- [ ] **AC4.5:** Evento `task_delivered` — Task marcada como delivered
- [ ] **AC4.6:** Evento `task_reopened` — Task reaberta (delivered → completed)
- [ ] **AC4.7:** Evento `daily_summary_viewed` — visita à `/resumo-diario`

### AC5 — Privacidade
- [ ] **AC5.1:** Não enviar PII (nome, email) como propriedade de evento
- [ ] **AC5.2:** user_id pseudonimizado (hash sha256 do user.id) para correlação sem identificação
- [ ] **AC5.3:** `.env.example` documenta `ANALYTICS_PROVIDER` e chave

### AC6 — Cobertura
- [ ] **AC6.1:** Spec verifica que helper de tracking renderiza script apenas em production
- [ ] **AC6.2:** Spec verifica que helper `track_event(:signup, ...)` chama API correta
- [ ] **AC6.3:** Specs de controller não disparam eventos em test (mock)

### AC7 — Dashboard de analytics validado
- [ ] **AC7.1:** Após deploy, criar conta de teste em produção e verificar eventos chegando
- [ ] **AC7.2:** Confirmar funil de onboarding (signup → step1 → step2 → complete)

---

## Análise Técnica

### Opção A — Plausible (recomendada)
**Prós:** cookie-less, GDPR/LGPD-friendly, simples (1 script), barato ($9/mês para 1 site)
**Contras:** menos eventos customizados, sem replay de sessão

```erb
<!-- application.html.erb head -->
<% if Rails.env.production? %>
  <script defer data-domain="cronos-poc.com" src="https://plausible.io/js/script.js"></script>
<% end %>
```

```erb
<!-- Helper para evento customizado -->
<%= javascript_tag do %>
  plausible('signup', { props: { method: 'google_oauth' } });
<% end %>
```

### Opção B — PostHog
**Prós:** free tier generoso, session replay, feature flags, funis nativos
**Contras:** mais complexo, requer cookie banner para conformidade UE/LGPD

```erb
<script>
  !function(t,e){var o,n,p,r;...}(document,window.posthog||[]);
  posthog.init('phc_KEY', { api_host: 'https://app.posthog.com' });
</script>
```

### Helper Rails

```ruby
# app/helpers/analytics_helper.rb
module AnalyticsHelper
  def track_event_tag(event_name, props = {})
    return unless Rails.env.production?
    return unless current_user # opcional

    javascript_tag do
      if plausible?
        "plausible(#{event_name.to_json}, { props: #{props.to_json} });".html_safe
      else
        "posthog.capture(#{event_name.to_json}, #{props.to_json});".html_safe
      end
    end
  end

  def plausible?
    Rails.application.config.analytics_provider == :plausible
  end
end
```

### Disparar evento server-side
Para eventos críticos (signup, task_delivered) que precisam ser registrados mesmo se JS falhar, usar HTTP request server-side:

```ruby
class AnalyticsService
  def self.track(user, event, props = {})
    return unless Rails.env.production?
    user_id_hash = Digest::SHA256.hexdigest(user.id.to_s)
    # POST para api do provider
  end
end
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/layouts/application.html.erb` | Adicionar script provider |
| `app/helpers/analytics_helper.rb` | Criar |
| `app/services/analytics_service.rb` | Criar |
| `app/controllers/companies_controller.rb` | Disparar `onboarding_step_1_complete` em create |
| `app/controllers/projects_controller.rb` | Disparar `onboarding_step_2_complete` em create |
| `app/controllers/tasks_controller.rb` | Disparar `onboarding_complete`, `task_delivered`, `task_reopened` |
| `app/controllers/omniauth_callbacks_controller.rb` | Disparar `signup` se user criado novo |
| `config/credentials.yml.enc` | Chave do provider |
| `.env.example` | Documentar |
| `spec/services/analytics_service_spec.rb` | Specs do service |

---

## Testes

- [ ] Service não dispara em test/dev (no-op)
- [ ] Mockado em prod, dispara HTTP com user_id_hash + event + props
- [ ] Suite continua 100%

---

## Observações

- **Recomendação:** começar com Plausible. Mais simples, sem cookie banner, suficiente para os 7 eventos críticos. Se precisar de session replay/feature flags depois, migrar para PostHog.
- **Custo Plausible:** $9/mês — para um SaaS em validação, justifica.
- **Custo PostHog cloud:** free até 1M events/mês — também justifica.
- **Self-hosting** dos dois é possível, mas complexidade não vale para 1-10 usuários.
