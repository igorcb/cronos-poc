# Deferred Work

## Deferred from: code review de 004-factories-specs-completos (2026-07-08)

- **MEDIUM — `belongs_to(:user)` testado só via `.macro`**: `spec/models/idle_period_spec.rb:4` verifica apenas `reflect_on_association(:user).macro == :belongs_to`, sem checar `optional: false` ou popular de fato a associação. Não é regressão desta story; reforçar com `build(:idle_period, user: nil)` inválido se a heurística de testes shoulda-matchers virar padrão obrigatório.
- **MEDIUM — `include("modal")` viola heurística AC8**: `spec/controllers/idle_periods_controller_spec.rb:107` usa `expect(response.body).to include("modal")`, um texto curto sem contexto específico (heurística firmada em architecture.md §7). Pré-existente das Stories 13.2/13.3, não introduzido pela Story 13.4. Ajustar para asserção mais específica ao tocar esse arquivo novamente.

## Deferred from: code review de 002-criar-viewcomponent-para-timeentry-card (2026-03-28)

- `Rails::Controller::Testing.install` como side-effect global em `spec/rails_helper.rb` — adicionado em Story 5.1, avaliar escopo ao implementar testes de controller futuros
- Testes de rendering em `status_badge_component_spec.rb` duplicam testes unitários de `badge_classes` — cobertura redundante, não prejudicial; limpar ao refatorar specs
- `<table>` sem `<thead>` com labels de coluna — cosmético; a view `index.html.erb` já tem thead, mas o componente não inclui cabeçalho; resolver ao implementar filtros ou totalizadores (DM-006)

## Deferred from: code review de 001-google-oauth-login (2026-05-23)

- **QA #10 MEDIUM — view spec ENV não thread-safe**: `spec/views/sessions/new.html.erb_spec.rb` manipula `ENV["GOOGLE_CLIENT_ID"]/SECRET` direto. Mitigado por `around ... ensure`, mas se Rails 8 parallel testing for habilitado, vira intermitente. Adotar `ClimateControl` gem quando habilitar paralelismo.
- **QA #13 LOW — extrair btn_primary_classes helper ou ViewComponent**: `app/views/sessions/new.html.erb` tem 2 botões com string Tailwind compartilhada. Não justifica abstração agora (apenas 2 ocorrências). Revisitar quando houver 3+ botões compartilhando o estilo.
- **QA #14 LOW — `change_column_null` lock em prod**: migration 20260523104408 usa `change_column_null` que pega ACCESS EXCLUSIVE lock no Postgres. Sem impacto agora (single-user). Adotar `gem "strong_migrations"` antes de Cronos virar multi-tenant em prod.
- **QA #15 LOW — audit/timestamp do link google_uid**: `User.from_google_omniauth` não registra timestamp de quando google_uid foi vinculado pela primeira vez. Fora do escopo da story 9.1; tratar em story futura de observabilidade ou perfil.
