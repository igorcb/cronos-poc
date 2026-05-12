# Deferred Work

## Deferred from: code review de 002-criar-viewcomponent-para-timeentry-card (2026-03-28)

- `Rails::Controller::Testing.install` como side-effect global em `spec/rails_helper.rb` — adicionado em Story 5.1, avaliar escopo ao implementar testes de controller futuros
- Testes de rendering em `status_badge_component_spec.rb` duplicam testes unitários de `badge_classes` — cobertura redundante, não prejudicial; limpar ao refatorar specs
- `<table>` sem `<thead>` com labels de coluna — cosmético; a view `index.html.erb` já tem thead, mas o componente não inclui cabeçalho; resolver ao implementar filtros ou totalizadores (DM-006)
