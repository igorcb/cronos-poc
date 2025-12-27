---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: ['prd.md']
workflowType: 'architecture'
project_name: 'cronos-poc'
user_name: 'Igor'
date: '2025-12-26'
lastStep: 4
---

# Architecture Decision Document - Cronos POC

**Autor:** Igor
**Data:** 2025-12-26

_Este documento é construído colaborativamente através de descoberta passo a passo. Seções são adicionadas conforme trabalhamos cada decisão arquitetural juntos._

## Análise de Contexto do Projeto

### Visão Geral do Produto

**Cronos POC** é um sistema web de timesheet desenvolvido para substituir planilhas Excel no controle de horas trabalhadas para múltiplas empresas. O sistema foca em três pilares fundamentais:

1. **Confiabilidade e Precisão:** Cálculos automáticos garantidos sem risco de erros humanos
2. **Visibilidade Clara:** Totalizadores em tempo real por empresa, projeto e período
3. **Velocidade no Registro:** Interface otimizada para entrada rápida (~30 segundos por registro)

**Fase Atual:** MVP single-user (ferramenta pessoal)
**Visão Futura:** Produto SaaS multi-tenant para profissionais autônomos

### Requisitos Funcionais

**Funcionalidades Core (MVP):**

1. **Registro de Entradas de Tempo**
   - Campos: Data, Início, Fim, Empresa (FK), Projeto (FK), Atividade, Status
   - Status: Pendente, Finalizado, Reaberto, Entregue
   - Formulário rápido com auto-preenchimentos e dropdowns

2. **Gestão de Empresas**
   - CRUD de empresas (nome, taxa R$/hora)
   - Empresas pré-cadastradas aparecem em dropdown no formulário
   - Taxa horária configurável por empresa

3. **Gestão de Projetos**
   - CRUD de projetos (nome, empresa associada)
   - Projetos organizados por empresa
   - Dropdown de projetos filtrado pela empresa selecionada

4. **Cálculos Automáticos**
   - Tempo trabalhado: Fim - Início (em horas/minutos)
   - Valor monetário: Tempo × Company.hourly_rate
   - Recalculo em tempo real após qualquer mudança

5. **Visualização e Listagem**
   - Lista completa de entradas do mês atual
   - Exibição: data, horários, tempo calculado, empresa.nome, projeto.nome, atividade, status, valor

6. **Totalizadores Dinâmicos**
   - Total de horas do dia atual
   - Total de horas por empresa no mês (GROUP BY company_id)
   - Total de valor por empresa no mês
   - Atualização automática após cada operação

7. **Filtros Interativos**
   - Por empresa (company_id), projeto (project_id), status, data/período
   - Aplicação instantânea (< 1s)
   - Totalizadores recalculados conforme filtro aplicado

8. **Edição de Entradas** (prioridade secundária no MVP)
   - Editar entradas existentes
   - Deletar entradas incorretas
   - Validações para prevenir inconsistências

**Fora do Escopo (Permanentemente ou Indefinidamente):**
- Multi-usuário / Multi-tenant
- Integração com ferramentas externas (Trello, Jira, etc)
- Timers automáticos
- Exportação Excel/CSV (pode ser considerado pós-MVP)
- Relatórios avançados ou gráficos (pode ser considerado pós-MVP)
- Notificações/lembretes (pode ser considerado pós-MVP)

### Requisitos Não-Funcionais

**Performance:**
- First Contentful Paint: < 1.5s
- Time to Interactive: < 3s
- Listagem de entradas do mês: < 2s
- Aplicação de filtros: < 1s
- Envio de formulário: < 500ms (com feedback visual imediato)
- Paginação/virtualização se > 200 entradas

**Responsividade:**
- Abordagem Mobile-First
- Breakpoints: Mobile (< 768px), Tablet (768-1023px), Desktop (≥ 1024px)
- Funcionalidade completa em todos os tamanhos de tela
- Navegadores: Chrome, Firefox, Safari (desktop/mobile), Edge (últimas 2 versões)

**Confiabilidade:**
- Cálculos matemáticos 100% precisos e testados
- Validação client-side e server-side
- Dados persistidos de forma segura
- Zero perda de dados
- Integridade referencial (FK constraints)

**Segurança:**
- Autenticação obrigatória (single-user)
- Proteção CSRF
- Sanitização de inputs
- HTTPS obrigatório

**Acessibilidade:**
- WCAG Nível A (básico)
- HTML semântico
- Navegação por teclado funcional
- Contraste mínimo 4.5:1

### Stack Tecnológico Definido

**Backend:**
- **Ruby on Rails 7.x+** - Framework full-stack
- **PostgreSQL** - Banco de dados relacional
- **ActiveRecord** - ORM e modelagem de dados

**Frontend:**
- **Hotwire (Turbo + Stimulus)** - Interatividade sem JavaScript pesado
  - Turbo Frames: Atualizações parciais (filtros, listas)
  - Turbo Streams: Broadcast de mudanças (criar/editar entradas)
  - Stimulus: Controllers JavaScript para validações e interações
- **Tailwind CSS** - Estilização utility-first e responsividade
- **ViewComponents ou Partials** - Componentes reutilizáveis

**Autenticação:**
- Session-based (Rails padrão) ou Devise (single-user simplificado)

**Deployment:**
- Hospedagem web padrão
- HTTPS obrigatório
- Backup automático de dados

### Escala e Complexidade

**Classificação:**
- **Tipo:** Web App Full-Stack
- **Domínio:** General / Productivity (Time Tracking)
- **Complexidade:** Baixa a Média
- **Contexto:** Greenfield (novo projeto)
- **Usuários:** Single-user (sem multi-tenancy)

**Componentes Arquiteturais Estimados:**

**Modelos de Dados (4 principais):**
- `User` - Usuário do sistema (single-user)
- `Company` - Empresas (com hourly_rate)
- `Project` - Projetos (belongs_to :company)
- `TimeEntry` - Entradas de tempo (belongs_to :company, :project, :user)

**Controllers (6-8):**
- `DashboardController` - Visão geral e totalizadores
- `TimeEntriesController` - CRUD de entradas
- `CompaniesController` - CRUD de empresas
- `ProjectsController` - CRUD de projetos
- `SessionsController` - Autenticação
- `FilterController` ou concerns - Lógica de filtros

**Views (8-12 principais):**
- Dashboard/index
- TimeEntries: index, new, edit, _form
- Companies: index, new, edit, _form
- Projects: index, new, edit, _form
- Sessions: new

**Stimulus Controllers (3-5):**
- `filter_controller.js` - Filtros dinâmicos
- `form_validation_controller.js` - Validações client-side
- `project_selector_controller.js` - Dropdown de projetos filtrado por empresa
- `totalizer_controller.js` - Atualização de totais

**ViewComponents/Partials (10-15):**
- TimeEntry card/row
- Totalizer badges
- Filter form
- Status badges
- Navigation
- Flash messages

**Complexidade de Dados:**
- Relacionamentos: `Company has_many :projects, has_many :time_entries`
- Relacionamentos: `Project belongs_to :company, has_many :time_entries`
- Relacionamentos: `TimeEntry belongs_to :company, :project, :user`
- Cálculos agregados: `SUM(duration) GROUP BY company_id, date`
- Índices: `company_id, project_id, user_id, date, status, created_at`

### Restrições e Dependências Técnicas

**Restrições Definidas:**
- Single-user permanentemente (não evoluir para multi-tenant)
- Sem integrações externas (Trello, Jira, etc)
- Sem real-time websockets (Turbo Streams suficiente)
- Sem SEO (ferramenta privada)

**Funcionalidades Pós-MVP (Potenciais):**
- Exportação Excel/CSV
- Relatórios formatados para envio
- Gráficos de distribuição de tempo
- Notificações/alertas
- Templates de atividades frequentes

### Preocupações Transversais Identificadas

**1. Modelagem de Dados e Integridade Referencial**
- Companies e Projects são tabelas separadas com CRUD completo
- TimeEntry referencia Company e Project via FK com constraints
- Dependent destroy strategies: O que acontece se deletar Company/Project com TimeEntries associadas?
- Validações: TimeEntry deve ter company_id e project_id obrigatórios
- Validação: Project.company_id deve coincidir com TimeEntry.company_id (consistência)

**2. Precisão de Cálculos**
- Cálculos de tempo (duration) devem ser exatos
- Cálculos monetários devem usar `decimal` (precision: 10, scale: 2), não Float
- `TimeEntry.calculated_value = duration * Company.hourly_rate`
- Testes unitários obrigatórios para toda lógica de cálculo
- Validações para prevenir dados inconsistentes (end_time < start_time)

**3. Performance de Queries**
- Filtros dinâmicos requerem queries otimizadas com joins
- Agregações: `TimeEntry.joins(:company).where(company_id: X).sum(:duration)`
- Eager loading obrigatório: `TimeEntry.includes(:company, :project)` para prevenir N+1
- Índices em colunas filtráveis: `company_id, project_id, date, status, user_id`
- Índices compostos para queries frequentes: `[user_id, date]`, `[company_id, date]`

**4. Experiência de Usuário**
- Feedback visual imediato após ações (Turbo Streams)
- Validações em tempo real (Stimulus)
- Dropdown de projetos filtrado dinamicamente pela empresa selecionada (Stimulus)
- Estados de loading durante operações
- Mensagens de erro descritivas

**5. Responsividade e Acessibilidade**
- Tailwind breakpoints consistentes
- Formulários otimizados para mobile (dropdowns touch-friendly)
- Navegação por teclado funcional
- Labels e mensagens de erro claras

**6. Testabilidade**
- Testes de modelo para cálculos, validações e associações
- Testes de sistema para fluxos completos (criar empresa → criar projeto → criar entrada)
- Testes de performance para queries com agregações
- Fixtures/factories para Companies, Projects, TimeEntries

**7. Simplicidade e Manutenibilidade**
- Single-user simplifica arquitetura (sem row-level security, sem tenant isolation)
- Separação clara de concerns (models, services, presenters)
- Company.hourly_rate configurável por empresa
- Código modular para facilitar adição de features pós-MVP

## Avaliação de Starter Template

### Domínio Tecnológico Principal

**Ruby on Rails Full-Stack Web Application** - Sistema monolítico com Hotwire para interatividade e Tailwind CSS para estilização.

### Versões Tecnológicas Atuais (Dezembro 2025)

**Ruby:**
- **Versão Latest:** Ruby 4.0.0 (lançado em 25/12/2025)
- **Versão Stable Recomendada:** Ruby 3.4.8 (lançado em 17/12/2025)
- **Decisão:** Usar Ruby 3.4.8 (stable, amplamente testado, produção-ready)

**Rails:**
- **Versão Latest:** Rails 8.1.1 (lançado em 28/10/2025)
- **Versão Stable:** Rails 8.0.4 (lançado em 28/10/2025)
- **Decisão:** Usar Rails 8.1.1 (inclui Hotwire nativo, melhorias de performance, Active Job Continuations)

### Comando de Inicialização do Projeto

```bash
rails new cronos-poc \
  --database=postgresql \
  --css=tailwind \
  --javascript=esbuild \
  --skip-test
```

**Explicação dos Parâmetros:**
- `--database=postgresql`: Configura PostgreSQL como banco de dados
- `--css=tailwind`: Instala e configura Tailwind CSS automaticamente via `tailwindcss-rails`
- `--javascript=esbuild`: Usa esbuild como bundler JavaScript (rápido, moderno)
- `--skip-test`: Pula Minitest (vamos configurar RSpec manualmente)

### Decisões Arquiteturais Fornecidas pelo Rails 8.1

**Language & Runtime:**
- Ruby 3.4.8 (stable, performance otimizada)
- Rails 8.1.1 (última versão com todas as features modernas)
- ActiveRecord como ORM

**Styling Solution:**
- Tailwind CSS 4.x configurado via `tailwindcss-rails` gem
- Propshaft como asset pipeline (padrão Rails 8, substitui Sprockets)
- `tailwind:watch` task para rebuild automático durante desenvolvimento
- Procfile.dev para gerenciar Rails server + Tailwind watcher

**Frontend Framework (Hotwire):**
- **Turbo Drive:** Navegação SPA-like sem full page reloads
- **Turbo Frames:** Atualizações parciais de página (ideal para filtros e listas)
- **Turbo Streams:** Broadcasts em tempo real (ideal para totalizadores dinâmicos)
- **Stimulus:** Controllers JavaScript leves para interatividade client-side
- Hotwire vem instalado por padrão no Rails 8 (gems `turbo-rails` e `stimulus-rails`)

**Build Tooling:**
- esbuild como JavaScript bundler (extremamente rápido)
- Propshaft para assets estáticos (images, fonts, etc.)
- Tailwind standalone executable para CSS processing
- Foreman para gerenciar processos de desenvolvimento

**Testing Framework:**
- Minitest removido (`--skip-test`)
- RSpec será adicionado manualmente via Gemfile:
  - `rspec-rails` para testes
  - `factory_bot_rails` para factories
  - `faker` para dados fake
  - `shoulda-matchers` para matchers adicionais

**Code Quality & Development Tools:**
- Gems a serem adicionadas manualmente:
  - `rubocop` e `rubocop-rails` para linting
  - `rubocop-rspec` para linting de testes
  - `bullet` para detectar N+1 queries (crítico para performance)
  - `annotate` para documentar schemas nos models
  - `pry-rails` para debugging

**Project Structure (Rails Conventions):**
```
cronos-poc/
├── app/
│   ├── controllers/        # Controllers (CRUD + Dashboard)
│   ├── models/             # ActiveRecord models
│   ├── views/              # ERB templates
│   │   └── layouts/        # Layout principal
│   ├── javascript/         # Stimulus controllers
│   │   └── controllers/    # project_selector, filter, etc.
│   ├── assets/
│   │   ├── stylesheets/    # Tailwind config
│   │   └── images/
│   └── components/         # ViewComponents (a adicionar)
├── config/
│   ├── database.yml        # PostgreSQL config
│   ├── routes.rb           # Rotas
│   └── tailwind.config.js  # Tailwind config
├── db/
│   └── migrate/            # Migrations
├── spec/                   # RSpec tests (a criar)
│   ├── models/
│   ├── requests/
│   └── system/
├── Dockerfile              # Docker setup (a criar)
├── docker-compose.yml      # Docker Compose (a criar)
├── Gemfile
└── Procfile.dev            # Dev processes (Rails + Tailwind)
```

**Development Experience:**
- Hot reloading automático (Turbo + Propshaft)
- `bin/dev` para iniciar servidor + watchers via Procfile.dev
- Debugging com Pry
- Console Rails (`rails console`)
- Database migrations (`rails db:migrate`)

**Database Configuration:**
- PostgreSQL configurado via `config/database.yml`
- Migrations para schema management
- Seeds para dados iniciais
- `database_cleaner` para testes (a adicionar)

**Containerização (Docker):**
- Dockerfile a ser criado manualmente:
  - Base image: `ruby:3.4.8-slim`
  - PostgreSQL client libraries
  - Node.js para asset compilation (esbuild)
  - Volume mounts para desenvolvimento

- docker-compose.yml a ser criado:
  - Service `web` (Rails app)
  - Service `db` (PostgreSQL 16)
  - Volume para persistência de dados
  - Network para comunicação entre services

**Autenticação:**
- `has_secure_password` (Rails built-in, simples para single-user)
- `bcrypt` gem já incluída no Gemfile
- Session-based authentication (cookies)

### Gems Adicionais a Instalar

**Testing:**
```ruby
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
end
```

**Code Quality:**
```ruby
group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'bullet'
  gem 'annotate'
  gem 'pry-rails'
end
```

**Production:**
```ruby
gem 'rack-timeout'  # Request timeout
gem 'lograge'       # Better logging
```

### Rationale for Technology Choices

**Rails 8.1 com Hotwire:**
- Hotwire nativo elimina necessidade de React/Vue para interatividade
- Turbo Frames ideal para filtros sem full page reload
- Turbo Streams perfeito para atualizar totalizadores em tempo real
- Reduz drasticamente JavaScript necessário
- Performance excelente (server-side rendering)

**Tailwind CSS:**
- Mobile-first por padrão (alinhado com requisitos)
- Utility classes aceleram desenvolvimento
- Sem CSS personalizado pesado
- Fácil manutenção e consistência
- Performance otimizada (tree-shaking automático)

**PostgreSQL:**
- Banco robusto e confiável
- Excelente para aggregations (SUM, GROUP BY)
- Suporte nativo a indexes compostos
- JSON columns se precisar no futuro
- Amplamente suportado em hospedagens

**Docker:**
- Ambiente consistente dev/prod
- Fácil setup para novos desenvolvedores
- Isolamento de dependências
- Deploy simplificado

**RSpec + FactoryBot:**
- Testes mais expressivos que Minitest
- FactoryBot simplifica criação de test data
- Amplamente usado na comunidade Rails
- Melhor para TDD/BDD

### Notas de Implementação

1. **Primeira Story:** Inicializar projeto com comando Rails
2. **Segunda Story:** Configurar Docker + docker-compose
3. **Terceira Story:** Adicionar gems de teste e qualidade
4. **Quarta Story:** Configurar RSpec e factories

**Comandos de Desenvolvimento:**
```bash
# Iniciar ambiente de desenvolvimento
docker-compose up

# Rodar migrations
docker-compose exec web rails db:migrate

# Rodar testes
docker-compose exec web bundle exec rspec

# Console Rails
docker-compose exec web rails console

# Gerar migration
docker-compose exec web rails generate migration CreateCompanies
```

## Decisões Arquiteturais Principais

### Resumo de Decisões por Prioridade

**Decisões Críticas (Bloqueiam Implementação):**
1. ✅ Validação em tripla camada (Model + Client + DB Constraints)
2. ✅ Soft Delete para Companies, Restrict para Projects
3. ✅ Rails 8 Authentication Generator para autenticação single-user
4. ✅ ViewComponent para componentes UI reutilizáveis
5. ✅ Concerns + Service Objects para lógica de negócio

**Decisões Importantes (Moldam Arquitetura):**
1. ✅ Query caching padrão Rails (fragment caching se necessário)
2. ✅ Rails Credentials para secrets
3. ✅ Sem gem de autorização (single-user, tudo autenticado)

**Decisões Definidas pelo Starter Template:**
- Ruby 3.4.8 + Rails 8.1.1
- PostgreSQL como database
- Hotwire (Turbo + Stimulus) para frontend
- Tailwind CSS para estilização
- RSpec + FactoryBot para testes
- Docker + Docker Compose para containerização

### Categoria 1: Arquitetura de Dados

**Decisão 1.1: Estratégia de Validação de Dados**

**Escolha:** Validações em Tripla Camada (Model + Client-side + Database Constraints)

**Implementação:**

**Camada 1 - Database Constraints:**
```ruby
# Migration example
class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.text :activity, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false
      t.decimal :calculated_value, precision: 10, scale: 2
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :time_entries, [:user_id, :date]
    add_index :time_entries, [:company_id, :date]
    add_index :time_entries, :status

    # Check constraint: end_time deve ser maior que start_time
    execute <<-SQL
      ALTER TABLE time_entries
      ADD CONSTRAINT check_end_after_start
      CHECK (end_time > start_time);
    SQL
  end
end
```

**Camada 2 - Model Validations (ActiveRecord):**
```ruby
# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :project

  # Validações de presença
  validates :date, :start_time, :end_time, :activity, :status, presence: true

  # Validação de status
  validates :status, inclusion: {
    in: %w[pending completed reopened delivered],
    message: "%{value} não é um status válido"
  }

  # Validação customizada: end_time > start_time
  validate :end_time_after_start_time

  # Validação: project pertence à company
  validate :project_belongs_to_company

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior ao horário de início")
    end
  end

  def project_belongs_to_company
    return if project.blank? || company.blank?

    if project.company_id != company_id
      errors.add(:project, "não pertence à empresa selecionada")
    end
  end
end
```

**Camada 3 - Client-side Validation (Stimulus):**
```javascript
// app/javascript/controllers/form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startTime", "endTime", "errorMessage"]

  validateTimes() {
    const start = this.startTimeTarget.value
    const end = this.endTimeTarget.value

    if (start && end && end <= start) {
      this.showError("Horário final deve ser posterior ao inicial")
      this.endTimeTarget.setCustomValidity("Invalid")
      return false
    } else {
      this.hideError()
      this.endTimeTarget.setCustomValidity("")
      return true
    }
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorMessageTarget.classList.add("hidden")
  }
}
```

**Rationale:**
- Database constraints: Última linha de defesa, impossível corromper dados
- Model validations: Lógica de negócio centralizada, reutilizável
- Client-side: Feedback imediato, melhor UX, reduz requests inválidos

**Impacto:**
- Confiabilidade máxima nos cálculos
- Zero chance de dados inconsistentes
- UX superior com validação em tempo real

---

**Decisão 1.2: Estratégia de Dependent Destroy**

**Escolha:**
- **Companies:** Soft Delete (campo `active`)
- **Projects:** `dependent: :restrict_with_error`

**Implementação:**

**Company Model (Soft Delete):**
```ruby
# Migration
class AddActiveToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :active, :boolean, default: true, null: false
    add_index :companies, :active
  end
end

# app/models/company.rb
class Company < ApplicationRecord
  has_many :projects
  has_many :time_entries

  # Scopes para filtrar ativos/inativos
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Soft delete ao invés de destroy
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Override destroy para prevenir deleção acidental
  def destroy
    if time_entries.exists?
      errors.add(:base, "Não é possível deletar empresa com entradas de tempo associadas. Use deactivate! para desativar.")
      throw(:abort)
    else
      super
    end
  end
end
```

**Project Model (Restrict Delete):**
```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :company
  has_many :time_entries, dependent: :restrict_with_error

  validates :name, presence: true
  validates :company_id, presence: true
end
```

**Rationale:**
- **Companies:** Contém `hourly_rate` crítico para cálculos históricos, nunca podem ser deletadas se tiverem dados
- **Projects:** Menos críticos, mas ainda protegidos contra deleção acidental
- Soft delete permite manter histórico completo para auditorias e relatórios
- Empresas inativas não aparecem em dropdowns, mas dados históricos permanecem intactos

**Impacto:**
- Zero perda de dados históricos de faturamento
- Auditorias completas sempre disponíveis
- Dropdowns mostram apenas empresas/projetos ativos

---

**Decisão 1.3: Estratégia de Caching**

**Escolha:** Query Caching padrão Rails + Fragment Caching para totalizadores se necessário

**Implementação Inicial (Query Caching):**
```ruby
# Rails automaticamente faz query caching dentro de uma request
# Sem código adicional necessário inicialmente

# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  # Métodos de agregação com queries otimizadas

  def self.total_hours_for_day(date, user)
    where(user: user, date: date)
      .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 3600")
  end

  def self.total_hours_by_company(month, year, user)
    where(user: user)
      .where("EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?", month, year)
      .group(:company_id)
      .select("company_id, SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600) as total_hours")
  end
end
```

**Fragment Caching (a ser adicionado se necessário):**
```erb
<!-- app/views/dashboard/_daily_totals.html.erb -->
<% cache ["daily-totals", @date, @user] do %>
  <div class="totals">
    <h3>Total do Dia: <%= @daily_total %> horas</h3>
  </div>
<% end %>

<!-- app/views/dashboard/_monthly_totals.html.erb -->
<% cache ["monthly-totals", @month, @year, @user, TimeEntry.maximum(:updated_at)] do %>
  <div class="company-totals">
    <% @company_totals.each do |company, hours| %>
      <div><%= company.name %>: <%= hours %> horas</div>
    <% end %>
  </div>
<% end %>
```

**Cache Invalidation (Turbo Streams):**
```ruby
# app/models/time_entry.rb
after_commit :broadcast_totals_update

private

def broadcast_totals_update
  broadcast_replace_to(
    "user_#{user_id}_totals",
    target: "daily_totals",
    partial: "dashboard/daily_totals",
    locals: { date: date, user: user }
  )
end
```

**Rationale:**
- Começar simples: query caching é automático e suficiente para < 200 entries
- Single-user simplifica invalidação de cache
- Fragment caching pode ser adicionado incrementalmente onde houver bottleneck
- Turbo Streams já atualiza UI em tempo real, reduzindo necessidade de cache agressivo

**Impacto:**
- Performance adequada para MVP
- Escalável: fácil adicionar fragment caching depois
- Complexidade mínima inicialmente

---

### Categoria 2: Autenticação & Segurança

**Decisão 2.1: Implementação de Autenticação**

**Escolha:** Rails 8 Authentication Generator

**Implementação:**
```bash
# Gerar autenticação básica do Rails 8
rails generate authentication

# Isso cria:
# - app/models/user.rb com has_secure_password
# - app/models/session.rb
# - app/controllers/sessions_controller.rb
# - app/controllers/concerns/authentication.rb
# - Views para login/signup
# - Migrations para users e sessions
```

**Customização para Single-User:**
```ruby
# db/seeds.rb
User.find_or_create_by!(email: ENV['ADMIN_EMAIL']) do |user|
  user.password = ENV['ADMIN_PASSWORD']
  user.password_confirmation = ENV['ADMIN_PASSWORD']
end

# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  # Desabilitar signup público
  before_action :redirect_to_login

  private

  def redirect_to_login
    redirect_to login_path, alert: "Registro desabilitado"
  end
end
```

**Rationale:**
- Rails 8 authentication generator é leve, moderno, sem gem extra
- Código no projeto (fácil customizar)
- Single-user: remover signup público, criar via seed
- Password reset via console se necessário (sem envio de email)

**Impacto:**
- Autenticação segura com BCrypt
- Session-based (cookies)
- Zero overhead de gems pesadas

---

**Decisão 2.2: Estratégia de Autorização**

**Escolha:** Sem gem de autorização (tudo autenticado tem acesso total)

**Implementação:**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication

  before_action :require_authentication

  private

  # Método do concern Authentication
  # Redireciona para login se não autenticado
end

# Todos os controllers herdam de ApplicationController
# Logo, tudo requer autenticação automaticamente
```

**Rationale:**
- Single-user significa que "autenticado = autorizado para tudo"
- Pundit/CanCanCan seria overhead desnecessário
- Simplicidade máxima

**Impacto:**
- Código mais limpo, menos gems
- Nenhuma lógica de roles/permissions
- Fácil adicionar autorização futuramente se necessário

---

**Decisão 2.3: Proteção de Dados Sensíveis**

**Escolha:** Rails Credentials (padrão Rails 8)

**Implementação:**
```bash
# Editar credentials
EDITOR="code --wait" rails credentials:edit

# config/credentials.yml.enc (criptografado)
database:
  password: <%= ENV['DATABASE_PASSWORD'] || Rails.application.credentials.dig(:database, :password) %>

secret_key_base: <gerado automaticamente>
```

**Acesso em código:**
```ruby
# config/database.yml
production:
  password: <%= Rails.application.credentials.dig(:database, :password) %>

# Qualquer lugar do código
Rails.application.credentials.database[:password]
```

**Setup:**
```bash
# master.key vai para .gitignore automaticamente
# Compartilhar master.key via canal seguro (1Password, etc.)

# Produção: definir RAILS_MASTER_KEY na env
export RAILS_MASTER_KEY=<conteudo do master.key>
```

**Rationale:**
- Rails credentials são padrão Rails 8, bem integrados
- Criptografado no repositório
- Simples para single-developer
- Preparado para produção

**Impacto:**
- Secrets seguros, versionados (criptografados)
- Sem dependência de gems externas
- Deploy simplificado (só precisa da master key)

---

### Categoria 3: Padrões de Código e Organização

**Decisão 3.1: Organização de Lógica de Negócio**

**Escolha:** Concerns + Service Objects quando necessário

**Implementação:**

**Concerns para Comportamentos Compartilhados:**
```ruby
# app/models/concerns/calculable.rb
module Calculable
  extend ActiveSupport::Concern

  included do
    before_save :calculate_duration
    before_save :calculate_value
  end

  def calculate_duration
    return unless start_time && end_time

    self.duration_minutes = ((end_time - start_time) / 60).to_i
  end

  def calculate_value
    return unless duration_minutes && company&.hourly_rate

    hours = duration_minutes / 60.0
    self.calculated_value = (hours * company.hourly_rate).round(2)
  end

  def formatted_duration
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    "#{hours}h#{minutes.to_s.rjust(2, '0')}m"
  end
end

# app/models/time_entry.rb
class TimeEntry < ApplicationRecord
  include Calculable

  # Model fica limpo, concerns separam responsabilidades
end
```

**Service Objects para Operações Complexas:**
```ruby
# app/services/monthly_report_generator.rb
class MonthlyReportGenerator
  def initialize(user, month, year)
    @user = user
    @month = month
    @year = year
  end

  def call
    {
      total_hours: total_hours,
      total_value: total_value,
      by_company: hours_by_company,
      by_project: hours_by_project,
      entries_count: entries.count
    }
  end

  private

  attr_reader :user, :month, :year

  def entries
    @entries ||= TimeEntry
      .where(user: user)
      .where("EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?", month, year)
      .includes(:company, :project)
  end

  def total_hours
    entries.sum(:duration_minutes) / 60.0
  end

  def total_value
    entries.sum(:calculated_value)
  end

  def hours_by_company
    entries.group(:company).sum(:duration_minutes).transform_values { |v| v / 60.0 }
  end

  def hours_by_project
    entries.group(:project).sum(:duration_minutes).transform_values { |v| v / 60.0 }
  end
end

# Uso no controller
class ReportsController < ApplicationController
  def monthly
    @report = MonthlyReportGenerator.new(current_user, params[:month], params[:year]).call
  end
end
```

**Quando usar cada um:**
- **Concerns:** Comportamentos compartilhados entre models (Calculable, Filterable, Searchable)
- **Service Objects:** Operações complexas, multi-step, que envolvem vários models
- **Models:** Lógica simples, relacionamentos, validações básicas

**Rationale:**
- Concerns mantêm models organizados sem criar abstrações prematuras
- Service Objects para lógica de negócio complexa (relatórios, processamentos)
- Balanceado: não over-engineer, mas permite crescimento limpo
- Testabilidade: Service Objects são POROs fáceis de testar

**Impacto:**
- Código organizado, fácil de testar
- Models não ficam "fat"
- Reutilização de lógica via concerns
- Service Objects facilitam adicionar features complexas

---

**Decisão 3.2: ViewComponents vs Partials**

**Escolha:** ViewComponent gem

**Instalação:**
```ruby
# Gemfile
gem 'view_component'

# bundle install
# rails generate view_component:install
```

**Implementação:**

**TimeEntry Card Component:**
```ruby
# app/components/time_entry_card_component.rb
class TimeEntryCardComponent < ViewComponent::Base
  attr_reader :entry

  def initialize(entry:)
    @entry = entry
  end

  def status_class
    {
      'pending' => 'bg-yellow-100 text-yellow-800',
      'completed' => 'bg-green-100 text-green-800',
      'reopened' => 'bg-orange-100 text-orange-800',
      'delivered' => 'bg-blue-100 text-blue-800'
    }[entry.status]
  end
end
```

```erb
<!-- app/components/time_entry_card_component.html.erb -->
<div class="p-4 border rounded-lg shadow-sm hover:shadow-md transition">
  <div class="flex justify-between items-start">
    <div>
      <h3 class="font-semibold text-lg"><%= entry.company.name %></h3>
      <p class="text-sm text-gray-600"><%= entry.project.name %></p>
    </div>
    <span class="px-2 py-1 rounded text-xs font-medium <%= status_class %>">
      <%= entry.status.titleize %>
    </span>
  </div>

  <div class="mt-3 grid grid-cols-2 gap-2 text-sm">
    <div>
      <span class="text-gray-500">Período:</span>
      <span class="font-medium"><%= entry.start_time.strftime('%H:%M') %> - <%= entry.end_time.strftime('%H:%M') %></span>
    </div>
    <div>
      <span class="text-gray-500">Duração:</span>
      <span class="font-medium"><%= entry.formatted_duration %></span>
    </div>
  </div>

  <div class="mt-2">
    <p class="text-sm text-gray-700"><%= entry.activity %></p>
  </div>

  <div class="mt-3 flex justify-between items-center">
    <span class="text-lg font-bold text-green-600">
      R$ <%= number_to_currency(entry.calculated_value, unit: '') %>
    </span>
    <div class="space-x-2">
      <%= link_to "Editar", edit_time_entry_path(entry), class: "text-blue-600 hover:underline text-sm" %>
      <%= button_to "Deletar", time_entry_path(entry), method: :delete, class: "text-red-600 hover:underline text-sm", data: { turbo_confirm: "Tem certeza?" } %>
    </div>
  </div>
</div>
```

**Uso na View:**
```erb
<!-- app/views/time_entries/index.html.erb -->
<div class="space-y-4">
  <% @time_entries.each do |entry| %>
    <%= render TimeEntryCardComponent.new(entry: entry) %>
  <% end %>
</div>
```

**Outros Components:**
```ruby
# app/components/status_badge_component.rb
class StatusBadgeComponent < ViewComponent::Base
  def initialize(status:)
    @status = status
  end

  # ... lógica de cores
end

# app/components/totalizer_component.rb
class TotalizerComponent < ViewComponent::Base
  def initialize(label:, value:, type: :hours)
    @label = label
    @value = value
    @type = type
  end

  # ... formatação de horas/valores
end
```

**Testes:**
```ruby
# spec/components/time_entry_card_component_spec.rb
require 'rails_helper'

RSpec.describe TimeEntryCardComponent, type: :component do
  let(:company) { create(:company, name: "Empresa Teste") }
  let(:project) { create(:project, company: company) }
  let(:entry) { create(:time_entry, company: company, project: project, status: 'pending') }

  it "renders company name" do
    render_inline(described_class.new(entry: entry))

    expect(page).to have_text("Empresa Teste")
  end

  it "applies correct status class" do
    render_inline(described_class.new(entry: entry))

    expect(page).to have_css('.bg-yellow-100')
  end
end
```

**Rationale:**
- ViewComponent encapsula lógica + template
- Testável isoladamente (unit tests para components)
- Evita lógica complexa em ERB
- Reutilização fácil (cards, badges, forms)
- Performance melhor que partials (caching nativo)

**Impacto:**
- UI consistente e reutilizável
- Testabilidade superior
- Código mais organizado
- Easier maintenance
