---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: ['prd.md', 'architecture.md']
workflowType: 'epics-and-stories'
project_name: 'cronos-poc'
user_name: 'Igor'
date: '2025-12-27'
lastStep: 4
totalEpics: 8
totalStories: 34
validated: true
readyForDevelopment: true
---

# cronos-poc - Epic Breakdown

## Overview

Este documento fornece o detalhamento completo de epics e stories para o **Cronos POC**, decompondo os requisitos do PRD, UX Design (não existe) e Architecture em stories implementáveis.

## Requirements Inventory

### Functional Requirements

**FR1:** Sistema deve permitir registro de entradas de tempo com campos: Data, Início, Fim, Empresa (FK), Projeto (FK), Atividade, Status
**FR2:** Status de entradas devem incluir: Pendente, Finalizado, Reaberto, Entregue
**FR3:** Sistema deve oferecer CRUD completo de empresas com campos: nome e taxa R$/hora
**FR4:** Sistema deve oferecer CRUD completo de projetos com campos: nome e empresa associada (FK)
**FR5:** Sistema deve calcular automaticamente tempo trabalhado (Fim - Início) em horas e minutos
**FR6:** Sistema deve calcular automaticamente valor monetário (Tempo × hourly_rate da empresa)
**FR7:** Sistema deve exibir lista de entradas do mês atual com todas as informações (data, horários, tempo calculado, empresa.nome, projeto.nome, atividade, status, valor)
**FR8:** Sistema deve calcular e exibir total de horas do dia atual
**FR9:** Sistema deve calcular e exibir total de horas por empresa no mês (GROUP BY company_id)
**FR10:** Sistema deve calcular e exibir total de valor monetário por empresa no mês
**FR11:** Sistema deve permitir filtros interativos por empresa (company_id)
**FR12:** Sistema deve permitir filtros interativos por projeto (project_id)
**FR13:** Sistema deve permitir filtros interativos por status
**FR14:** Sistema deve permitir filtros interativos por data/período
**FR15:** Sistema deve recalcular totalizadores automaticamente após aplicação de filtros
**FR16:** Sistema deve permitir edição de entradas existentes (prioridade secundária no MVP)
**FR17:** Sistema deve permitir deleção de entradas incorretas (prioridade secundária no MVP)

### NonFunctional Requirements

**NFR1:** First Contentful Paint deve ser < 1.5s
**NFR2:** Time to Interactive deve ser < 3s
**NFR3:** Listagem de entradas do mês deve carregar em < 2s
**NFR4:** Aplicação de filtros deve retornar resultados em < 1s
**NFR5:** Envio de formulário deve ter feedback visual em < 500ms
**NFR6:** Sistema deve implementar paginação/virtualização se houver > 200 entradas
**NFR7:** Interface deve seguir abordagem Mobile-First
**NFR8:** Sistema deve ser totalmente funcional em Mobile (< 768px), Tablet (768-1023px) e Desktop (≥ 1024px)
**NFR9:** Sistema deve ser compatível com Chrome, Firefox, Safari (desktop/mobile), Edge (últimas 2 versões)
**NFR10:** Cálculos matemáticos devem ser 100% precisos e testados
**NFR11:** Sistema deve implementar validação client-side E server-side
**NFR12:** Dados devem ser persistidos de forma segura sem risco de perda
**NFR13:** Sistema deve garantir integridade referencial (FK constraints no banco)
**NFR14:** Sistema deve exigir autenticação obrigatória (single-user)
**NFR15:** Sistema deve implementar proteção CSRF
**NFR16:** Sistema deve sanitizar inputs antes de processar
**NFR17:** Sistema deve usar HTTPS obrigatório
**NFR18:** Sistema deve seguir WCAG Nível A (básico) para acessibilidade
**NFR19:** Sistema deve usar HTML semântico
**NFR20:** Sistema deve permitir navegação completa por teclado
**NFR21:** Contraste mínimo de cores deve ser 4.5:1

### Additional Requirements

#### Infraestrutura e Setup

**ARQ1:** Projeto deve ser inicializado com Rails 8.1.1 usando comando `rails new cronos-poc --database=postgresql --css=tailwind --javascript=esbuild --skip-test`
**ARQ2:** Sistema deve usar Ruby 3.4.8 (stable)
**ARQ3:** Sistema deve usar Rails 8.1.1 (latest)
**ARQ4:** Sistema deve usar PostgreSQL como banco de dados
**ARQ5:** Sistema deve usar Hotwire (Turbo + Stimulus) para interatividade frontend
**ARQ6:** Sistema deve usar Tailwind CSS para estilização
**ARQ7:** Sistema deve usar Docker + Docker Compose para containerização
**ARQ8:** Dockerfile deve usar base image `ruby:3.4.8-slim`
**ARQ9:** Docker Compose deve incluir service `web` (Rails app) e service `db` (PostgreSQL 16)

#### Testing e Qualidade

**ARQ10:** Sistema deve usar RSpec ao invés de Minitest
**ARQ11:** Sistema deve usar FactoryBot para test data
**ARQ12:** Sistema deve usar Faker para dados fake
**ARQ13:** Sistema deve usar Shoulda Matchers para matchers adicionais
**ARQ14:** Sistema deve usar Rubocop e rubocop-rails para linting
**ARQ15:** Sistema deve usar Bullet para detectar N+1 queries
**ARQ16:** Sistema deve usar Annotate para documentar schemas nos models

#### Validação de Dados (Tripla Camada)

**ARQ17:** Migrations devem implementar constraints de banco (null: false, foreign keys, check constraints)
**ARQ18:** Migrations devem SEMPRE usar `if_not_exists: true` ao criar tabelas, colunas e índices
**ARQ19:** Models devem implementar validações ActiveRecord (presence, inclusion, validações customizadas)
**ARQ20:** Frontend deve implementar validações client-side com Stimulus controllers
**ARQ21:** Tabela time_entries deve ter check constraint garantindo end_time > start_time

#### Modelagem de Dados

**ARQ22:** Companies devem implementar soft delete com campo `active` (boolean, default: true)
**ARQ23:** Projects devem usar `dependent: :restrict_with_error` para prevenir deleção acidental
**ARQ24:** TimeEntry deve armazenar hourly_rate da empresa no momento do registro (desnormalização intencional)
**ARQ25:** Campos monetários devem usar tipo `decimal` com precision: 10, scale: 2 (NUNCA Float)
**ARQ26:** TimeEntry deve ter campo `duration_minutes` (integer) calculado automaticamente
**ARQ27:** TimeEntry deve ter campo `calculated_value` (decimal) calculado automaticamente

#### Autenticação e Segurança

**ARQ28:** Sistema deve usar Rails 8 Authentication Generator (`rails generate authentication`)
**ARQ29:** Autenticação deve ser session-based com cookies (não JWT)
**ARQ30:** Registro público (signup) deve ser desabilitado (single-user via seed)
**ARQ31:** Usuário admin deve ser criado via seed com ENV['ADMIN_EMAIL'] e ENV['ADMIN_PASSWORD']
**ARQ32:** Sistema deve usar Rails Credentials para secrets
**ARQ33:** Sem gem de autorização (autenticado = autorizado para tudo)

#### Performance e Caching

**ARQ34:** Sistema deve usar query caching padrão do Rails
**ARQ35:** Fragment caching pode ser adicionado incrementalmente se necessário
**ARQ36:** Queries devem usar eager loading (`includes`, `preload`) para prevenir N+1
**ARQ37:** Índices devem ser criados em: company_id, project_id, user_id, date, status
**ARQ38:** Índices compostos devem ser criados em: [user_id, date], [company_id, date]

#### Organização de Código

**ARQ39:** Sistema deve usar ViewComponent gem para componentes UI reutilizáveis
**ARQ40:** Lógica de negócio compartilhada deve usar Concerns (ex: Calculable)
**ARQ41:** Operações complexas multi-step devem usar Service Objects
**ARQ42:** Models devem focar em relacionamentos e validações básicas

#### Padrões de Implementação

**ARQ43:** Naming: Tabelas em snake_case plural (time_entries, companies)
**ARQ44:** Naming: Colunas em snake_case (company_id, hourly_rate)
**ARQ45:** Naming: Turbo Frames devem usar padrão `resource_action` (ex: time_entry_form)
**ARQ46:** Naming: Stimulus controllers devem usar padrão `feature_controller.js` (ex: form_validation_controller.js)
**ARQ47:** Testes RSpec devem seguir estrutura: spec/models, spec/requests, spec/system, spec/components

### FR Coverage Map

**FR1:** Epic 4 - Registro de entradas de tempo
**FR2:** Epic 4 - Status de entradas (Pendente, Finalizado, Reaberto, Entregue)
**FR3:** Epic 2 - CRUD de empresas
**FR4:** Epic 3 - CRUD de projetos
**FR5:** Epic 4 - Cálculo automático de tempo trabalhado
**FR6:** Epic 4 - Cálculo automático de valor monetário
**FR7:** Epic 5 - Lista de entradas do mês
**FR8:** Epic 5 - Total de horas do dia
**FR9:** Epic 5 - Total de horas por empresa no mês
**FR10:** Epic 5 - Total de valor por empresa no mês
**FR11:** Epic 6 - Filtro por empresa
**FR12:** Epic 6 - Filtro por projeto
**FR13:** Epic 6 - Filtro por status
**FR14:** Epic 6 - Filtro por data/período
**FR15:** Epic 6 - Recalculo de totalizadores após filtros
**FR16:** Epic 7 - Edição de entradas
**FR17:** Epic 7 - Deleção de entradas

**NFRs:** Distribuídos entre Epic 1 (segurança), Epic 4 (confiabilidade), Epic 5 (performance), Epic 8 (responsividade/acessibilidade)

**ARQs:** Epic 1 cobre setup/infraestrutura, demais epics implementam padrões arquiteturais conforme necessário

## Epic List

### Epic 1: Infraestrutura e Autenticação
**Objetivo:** Igor pode acessar o sistema de forma segura e o ambiente está pronto para desenvolvimento

**Valor do Usuário:** Sistema funcional com login seguro, pronto para cadastrar dados

**FRs Cobertos:** ARQ1-ARQ9 (setup Rails/Docker), ARQ10-ARQ16 (testes), ARQ28-ARQ33 (autenticação), NFR14-NFR17 (segurança)

### Epic 2: Gestão de Empresas
**Objetivo:** Igor pode cadastrar, editar e gerenciar empresas com suas taxas horárias

**Valor do Usuário:** Todas as empresas que Igor trabalha estão cadastradas com valores R$/hora corretos

**FRs Cobertos:** FR3, ARQ22, ARQ43-ARQ44

### Epic 3: Gestão de Projetos
**Objetivo:** Igor pode cadastrar e organizar projetos associados às empresas

**Valor do Usuário:** Todos os projetos estão organizados por empresa, facilitando seleção ao registrar horas

**FRs Cobertos:** FR4, ARQ23

### Epic 4: Registro de Entradas de Tempo
**Objetivo:** Igor pode registrar rapidamente suas horas trabalhadas com cálculos automáticos

**Valor do Usuário:** Registro de tempo em ~30 segundos, cálculos precisos sem erros, dados confiáveis

**FRs Cobertos:** FR1, FR2, FR5, FR6, ARQ17-ARQ21, ARQ24-ARQ27, ARQ40-ARQ42, NFR10-NFR13

### Epic 5: Visualização e Totalizadores
**Objetivo:** Igor pode ver todas as suas entradas e totais calculados automaticamente

**Valor do Usuário:** Visibilidade clara de quanto trabalhou (dia, mês, por empresa), dados prontos para faturamento

**FRs Cobertos:** FR7, FR8, FR9, FR10, ARQ34-ARQ38, ARQ39, NFR1-NFR6

### Epic 6: Filtros Dinâmicos
**Objetivo:** Igor pode filtrar entradas por empresa, projeto, status e data para análises específicas

**Valor do Usuário:** Fechamento de mês em minutos (não horas), isolamento de dados por empresa, análises semanais

**FRs Cobertos:** FR11, FR12, FR13, FR14, FR15, ARQ45-ARQ46, NFR4

### Epic 7: Edição e Correção de Entradas
**Objetivo:** Igor pode corrigir erros em entradas registradas sem medo de "quebrar" dados

**Valor do Usuário:** Correção rápida e segura de erros, recalculo automático de totais

**FRs Cobertos:** FR16, FR17

### Epic 8: Responsividade e Experiência Mobile
**Objetivo:** Igor pode usar o sistema em qualquer dispositivo (desktop, tablet, mobile)

**Valor do Usuário:** Registro de horas pelo celular, interface touch-friendly, formulários otimizados

**FRs Cobertos:** NFR7-NFR9, NFR18-NFR21

---

## Epic 1: Infraestrutura e Autenticação

**Objetivo:** Igor pode acessar o sistema de forma segura e o ambiente está pronto para desenvolvimento

### Story 1.1: Inicializar Projeto Rails com Starter Template

**Como** desenvolvedor
**Quero** inicializar o projeto Rails 8.1.1 com todas as configurações base
**Para que** eu tenha um ambiente funcional pronto para desenvolvimento

**Acceptance Criteria:**

**Given** que estou iniciando um novo projeto
**When** executo o comando `rails new cronos-poc --database=postgresql --css=tailwind --javascript=esbuild --skip-test`
**Then** projeto Rails 8.1.1 é criado com Ruby 3.4.8
**And** PostgreSQL está configurado como database padrão
**And** Tailwind CSS está instalado e configurado
**And** esbuild está configurado como bundler JavaScript
**And** Hotwire (Turbo + Stimulus) vem instalado por padrão
**And** Minitest foi removido (--skip-test)

### Story 1.2: Configurar Docker e Docker Compose

**Como** desenvolvedor
**Quero** containerizar a aplicação com Docker
**Para que** eu tenha ambiente consistente e isolado para desenvolvimento

**Acceptance Criteria:**

**Given** que o projeto Rails está inicializado
**When** crio Dockerfile e docker-compose.yml
**Then** Dockerfile usa base image `ruby:3.4.8-slim`
**And** docker-compose.yml define service `web` (Rails app)
**And** docker-compose.yml define service `db` (PostgreSQL 16)
**And** volumes estão configurados para persistência de dados
**And** `docker-compose up` inicia ambos os services sem erros
**And** Rails app é acessível em `http://localhost:3000`

### Story 1.3: Configurar RSpec e Factories

**Como** desenvolvedor
**Quero** configurar framework de testes RSpec
**Para que** eu possa escrever testes automatizados desde o início

**Acceptance Criteria:**

**Given** que o projeto está com Docker configurado
**When** adiciono gems de teste ao Gemfile (rspec-rails, factory_bot_rails, faker, shoulda-matchers, database_cleaner-active_record)
**Then** `bundle install` executa sem erros
**And** `rails generate rspec:install` cria estrutura spec/
**And** spec/rails_helper.rb está configurado com FactoryBot e Shoulda Matchers
**And** `bundle exec rspec` executa sem erros (0 examples, 0 failures)
**And** estrutura de pastas criada: spec/models, spec/requests, spec/system, spec/components

### Story 1.4: Configurar Code Quality Tools

**Como** desenvolvedor
**Quero** configurar ferramentas de qualidade de código
**Para que** o código siga padrões consistentes e detecte problemas automaticamente

**Acceptance Criteria:**

**Given** que RSpec está configurado
**When** adiciono gems de qualidade (rubocop, rubocop-rails, rubocop-rspec, bullet, annotate, pry-rails)
**Then** `bundle install` executa sem erros
**And** `.rubocop.yml` está criado com configurações Rails
**And** `bundle exec rubocop` executa sem erros críticos
**And** Bullet está configurado em config/environments/development.rb para detectar N+1 queries
**And** Annotate está configurado para rodar após migrations

### Story 1.5: Implementar Autenticação Single-User com Rails 8 Generator

**Como** Igor (usuário do sistema)
**Quero** fazer login de forma segura no sistema
**Para que** apenas eu tenha acesso aos meus dados de timesheet

**Acceptance Criteria:**

**Given** que as ferramentas de qualidade estão configuradas
**When** executo `rails generate authentication`
**Then** model User é criado com has_secure_password
**And** model Session é criado
**And** SessionsController é criado com actions new, create, destroy
**And** concern Authentication é criado em app/controllers/concerns/
**And** views de login (sessions/new) são criadas
**And** migrations para users e sessions são criadas
**And** routes para login, logout são configuradas
**And** `rails db:migrate` executa sem erros

### Story 1.6: Desabilitar Signup Público e Criar Seed de Usuário Admin

**Como** Igor
**Quero** que apenas eu possa acessar o sistema (single-user)
**Para que** não haja risco de outras pessoas criarem contas

**Acceptance Criteria:**

**Given** que autenticação Rails 8 está configurada
**When** desabilito signup público no RegistrationsController
**Then** rota de registro `/signup` redireciona para `/login` com mensagem "Registro desabilitado"
**And** db/seeds.rb cria usuário admin com `ENV['ADMIN_EMAIL']` e `ENV['ADMIN_PASSWORD']`
**And** `User.find_or_create_by!` garante idempotência do seed
**And** `rails db:seed` cria usuário sem erros
**And** consigo fazer login com credenciais do usuário admin
**And** após login, sou redirecionado para root_path

### Story 1.7: Configurar Rails Credentials para Secrets

**Como** desenvolvedor
**Quero** armazenar secrets de forma segura
**Para que** credenciais não sejam expostas no código

**Acceptance Criteria:**

**Given** que autenticação está funcionando
**When** configuro Rails Credentials
**Then** `master.key` está em .gitignore
**And** `config/credentials.yml.enc` está versionado (criptografado)
**And** `EDITOR="code --wait" rails credentials:edit` abre arquivo descriptografado
**And** secret_key_base está presente em credentials
**And** database password pode ser lida de credentials ou ENV
**And** config/database.yml usa `Rails.application.credentials.dig(:database, :password)` como fallback

---

## Epic 2: Gestão de Empresas

**Objetivo:** Igor pode cadastrar, editar e gerenciar empresas com suas taxas horárias

### Story 2.1: Criar Model e Migration de Companies com Soft Delete

**Como** desenvolvedor
**Quero** criar a tabela companies com campos necessários
**Para que** Igor possa cadastrar as empresas que trabalha

**Acceptance Criteria:**

**Given** que a autenticação está funcional
**When** crio migration CreateCompanies
**Then** migration usa `create_table :companies, if_not_exists: true`
**And** tabela possui coluna `name` (string, null: false)
**And** tabela possui coluna `hourly_rate` (decimal, precision: 10, scale: 2, null: false)
**And** tabela possui coluna `active` (boolean, default: true, null: false)
**And** tabela possui timestamps (created_at, updated_at)
**And** índice criado em `active` com `if_not_exists: true`
**And** model Company é criado com validações: `validates :name, :hourly_rate, presence: true`
**And** model possui scopes: `scope :active, -> { where(active: true) }`
**And** model possui métodos `deactivate!` e `activate!`
**And** `rails db:migrate` executa sem erros

### Story 2.2: Implementar CRUD de Companies (Index e New/Create)

**Como** Igor
**Quero** visualizar lista de empresas e cadastrar novas empresas
**Para que** eu possa gerenciar as empresas que trabalho

**Acceptance Criteria:**

**Given** que a tabela companies existe
**When** crio CompaniesController com actions index, new, create
**Then** rota `GET /companies` exibe lista de empresas ativas
**And** lista mostra: nome, taxa R$/hora, data de criação
**And** rota `GET /companies/new` exibe formulário de cadastro
**And** formulário possui campos: name (text), hourly_rate (number)
**And** rota `POST /companies` cria nova empresa e redireciona para index
**And** flash message de sucesso é exibida: "Empresa cadastrada com sucesso"
**And** validações são aplicadas: name e hourly_rate obrigatórios
**And** erro de validação exibe mensagens claras no formulário
**And** controller exige autenticação (`before_action :require_authentication`)

### Story 2.3: Implementar Edit/Update de Companies

**Como** Igor
**Quero** editar informações de empresas existentes
**Para que** eu possa corrigir dados ou atualizar taxas horárias

**Acceptance Criteria:**

**Given** que empresas estão cadastradas
**When** adiciono actions edit, update ao CompaniesController
**Then** rota `GET /companies/:id/edit` exibe formulário preenchido
**And** formulário permite editar name e hourly_rate
**And** rota `PATCH /companies/:id` atualiza empresa e redireciona para index
**And** flash message de sucesso: "Empresa atualizada com sucesso"
**And** validações são aplicadas na atualização
**And** erros de validação são exibidos no formulário
**And** não é possível editar campo `active` pelo formulário (apenas via deactivate!)

### Story 2.4: Implementar Soft Delete de Companies

**Como** Igor
**Quero** desativar empresas ao invés de deletá-las
**Para que** dados históricos sejam preservados

**Acceptance Criteria:**

**Given** que empresas estão cadastradas
**When** adiciono action destroy ao CompaniesController
**Then** rota `DELETE /companies/:id` chama `company.deactivate!`
**And** empresa tem campo `active` atualizado para `false`
**And** empresa desativada não aparece mais em `Company.active`
**And** empresa desativada não aparece na lista index
**And** flash message: "Empresa desativada com sucesso"
**And** tentativa de `destroy` hard delete é bloqueada se houver time_entries associadas
**And** link "Desativar" aparece na lista de empresas

### Story 2.5: Criar Factory e Testes de Model para Company

**Como** desenvolvedor
**Quero** testes automatizados para o model Company
**Para que** validações e comportamentos sejam garantidos

**Acceptance Criteria:**

**Given** que RSpec está configurado
**When** crio factory para Company em spec/factories/companies.rb
**Then** factory possui: `name { Faker::Company.name }`, `hourly_rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }`
**And** testes de validação confirmam presence de name e hourly_rate
**And** teste confirma que scope `active` retorna apenas empresas ativas
**And** teste confirma que `deactivate!` muda active para false
**And** teste confirma que `activate!` muda active para true
**And** `bundle exec rspec spec/models/company_spec.rb` passa 100%

---

## Epic 3: Gestão de Projetos

**Objetivo:** Igor pode cadastrar e organizar projetos associados às empresas

### Story 3.1: Criar Model e Migration de Projects com Foreign Key

**Como** desenvolvedor
**Quero** criar a tabela projects associada a companies
**Para que** Igor possa organizar projetos por empresa

**Acceptance Criteria:**

**Given** que a tabela companies existe
**When** crio migration CreateProjects
**Then** migration usa `create_table :projects, if_not_exists: true`
**And** tabela possui coluna `name` (string, null: false)
**And** tabela possui `t.references :company, null: false, foreign_key: true, if_not_exists: true`
**And** tabela possui timestamps
**And** índice criado em `company_id` com `if_not_exists: true`
**And** model Project é criado com: `belongs_to :company`
**And** model possui: `has_many :time_entries, dependent: :restrict_with_error`
**And** validações: `validates :name, :company_id, presence: true`
**And** `rails db:migrate` executa sem erros

### Story 3.2: Implementar CRUD de Projects (Index e New/Create)

**Como** Igor
**Quero** visualizar projetos e cadastrar novos projetos associados a empresas
**Para que** eu possa organizar meu trabalho por projeto

**Acceptance Criteria:**

**Given** que a tabela projects existe
**When** crio ProjectsController com actions index, new, create
**Then** rota `GET /projects` exibe lista de projetos
**And** lista mostra: nome do projeto, empresa associada, data de criação
**And** rota `GET /projects/new` exibe formulário de cadastro
**And** formulário possui: name (text), company_id (select dropdown)
**And** dropdown de empresas mostra apenas `Company.active`
**And** rota `POST /projects` cria projeto e redireciona para index
**And** flash message: "Projeto cadastrado com sucesso"
**And** validações aplicadas: name e company_id obrigatórios
**And** controller exige autenticação

### Story 3.3: Implementar Edit/Update e Destroy de Projects

**Como** Igor
**Quero** editar ou deletar projetos
**Para que** eu possa manter dados organizados

**Acceptance Criteria:**

**Given** que projetos estão cadastrados
**When** adiciono actions edit, update, destroy ao ProjectsController
**Then** rota `GET /projects/:id/edit` exibe formulário preenchido
**And** formulário permite editar name e company_id
**And** rota `PATCH /projects/:id` atualiza e redireciona para index
**And** flash message: "Projeto atualizado com sucesso"
**And** rota `DELETE /projects/:id` tenta deletar projeto
**And** se projeto tem time_entries associadas, erro é exibido: "Não é possível deletar projeto com entradas de tempo"
**And** se projeto NÃO tem time_entries, deleção ocorre com sucesso
**And** flash message de sucesso: "Projeto deletado com sucesso"

### Story 3.4: Criar Factory e Testes para Project

**Como** desenvolvedor
**Quero** testes automatizados para Project
**Para que** relacionamentos e validações sejam garantidos

**Acceptance Criteria:**

**Given** que RSpec está configurado
**When** crio factory para Project
**Then** factory possui: `association :company`, `name { Faker::App.name }`
**And** testes confirmam validação de presence: name, company_id
**And** teste confirma associação `belongs_to :company`
**And** teste confirma `dependent: :restrict_with_error` bloqueia deleção se houver time_entries
**And** `bundle exec rspec spec/models/project_spec.rb` passa 100%

---

## Epic 4: Task Management System - Registro e Gestão de Tarefas

**⚠️ IMPORTANTE:** Epic 4 foi **reformulado** baseado na retrospectiva do Epic 3. Mudou de TimeEntry simples para **Task Management System** com Tasks + TaskItems.

**Objetivo:** Igor pode registrar e gerenciar tarefas com tracking automático de tempo e status

**Mudança Arquitetural:**
- **Original:** TimeEntries (registro simples de tempo)
- **Novo:** Tasks (gerenciáveis) + TaskItems (registro granular de horas)

---

### Story 4.1: Criar Model Task com Validações Tripla Camada

**Como** desenvolvedor
**Quero** criar tabela tasks com validações robustas
**Para que** dados sejam 100% confiáveis

**Acceptance Criteria:**

**Given** que tables companies e projects existem
**When** crio migration CreateTasks
**Then** migration usa `create_table :tasks, if_not_exists: true`
**And** possui `t.string :name, null: false`
**And** possui `t.references :company, null: false, foreign_key: true, if_not_exists: true`
**And** possui `t.references :project, null: false, foreign_key: true, if_not_exists: true`
**And** possui `t.date :start_date, null: false`
**And** possui `t.date :end_date`
**And** possui `t.string :status, null: false, default: 'pending'`
**And** possui `t.date :delivery_date`
**And** possui `t.decimal :estimated_hours, precision: 10, scale: 2, null: false`
**And** possui `t.decimal :validated_hours, precision: 10, scale: 2`
**And** possui `t.text :notes`
**And** possui timestamps
**And** índices criados: `company_id`, `project_id`, `status`, `[company_id, project_id]` com `if_not_exists: true`
**And** model Task possui validações: presence de name, company, project, start_date, estimated_hours, status
**And** model possui enum status: { pending: 'pending', completed: 'completed', delivered: 'delivered' }
**And** model possui validação customizada: project.company_id == company_id
**And** `rails db:migrate` executa sem erros

### Story 4.2: Criar Model TaskItem com Validações e Cálculos

**Como** desenvolvedor
**Quero** criar tabela task_items para registro granular de horas
**Para que** cada período de trabalho seja registrado individualmente

**Acceptance Criteria:**

**Given** que tabela tasks existe
**When** crio migration CreateTaskItems
**Then** migration usa `create_table :task_items, if_not_exists: true`
**And** possui `t.references :task, null: false, foreign_key: true, if_not_exists: true`
**And** possui `t.time :start_time, null: false`
**And** possui `t.time :end_time, null: false`
**And** possui `t.decimal :hours_worked, precision: 10, scale: 2, null: false`
**And** possui `t.string :status, null: false, default: 'pending'`
**And** possui timestamps
**And** índices criados: `task_id`, `status`, `[task_id, created_at]` com `if_not_exists: true`
**And** model TaskItem possui validações: presence de task, start_time, end_time, status
**And** model possui enum status: { pending: 'pending', completed: 'completed' }
**And** model possui validação customizada: end_time > start_time
**And** model possui validação customizada: task não pode ser 'delivered'
**And** model possui before_save :calculate_hours_worked
**And** model possui after_save :update_task_status
**And** model possui after_destroy :update_task_status
**And** `rails db:migrate` executa sem erros

### Story 4.3: Implementar Lógica de Status Automático e Cálculos

**Como** desenvolvedor
**Quero** que Task status atualize automaticamente baseado em TaskItems
**Para que** usuário não precise gerenciar status manualmente

**Acceptance Criteria:**

**Given** que models Task e TaskItem existem
**When** implemento lógica de status automático
**Then** Task possui método `recalculate_status!` que verifica último TaskItem criado
**And** se último TaskItem criado está 'completed', Task status = 'completed'
**And** se último TaskItem criado está 'pending', Task status = 'pending'
**And** Task com status 'delivered' NÃO recalcula status (read-only)
**And** Task possui before_save :update_end_date quando status → 'completed'
**And** Task possui before_save :update_delivery_date quando status → 'delivered'
**And** Task possui after_save :recalculate_validated_hours
**And** Task possui método `total_hours` que soma task_items.hours_worked
**And** Task possui método `calculated_value` que calcula company.hourly_rate * total_hours
**And** TaskItem callback `calculate_hours_worked` calcula (end_time - start_time) / 3600.0
**And** TaskItem callback `update_task_status` chama task.recalculate_status!
**And** testes confirmam status atualiza corretamente

### Story 4.4: Implementar CRUD de Tasks (New/Create)

**Como** Igor
**Quero** criar novas tarefas rapidamente
**Para que** eu possa organizar meu trabalho

**Acceptance Criteria:**

**Given** que models e validações estão implementados
**When** crio TasksController com actions new, create
**Then** rota `GET /tasks/new` exibe formulário
**And** formulário possui: name (text), start_date (date picker), estimated_hours (number)
**And** formulário possui: company_id (select), project_id (select), notes (textarea)
**And** dropdown de companies mostra apenas `Company.active`
**And** dropdown de projects é filtrado por company selecionada (Stimulus)
**And** validação client-side confirma project pertence à company
**And** rota `POST /tasks` cria task com status 'pending'
**And** flash message: "Tarefa criada com sucesso"
**And** validações tripla camada aplicam (migration, model, client-side)
**And** tempo médio de criação < 45 segundos

### Story 4.5: Implementar Project Selector Dinâmico com Stimulus

**Como** Igor
**Quero** que projetos sejam filtrados pela empresa selecionada
**Para que** eu não veja projetos de outras empresas

**Acceptance Criteria:**

**Given** que formulário de Task existe
**When** crio `project_selector_controller.js` em Stimulus
**Then** ao selecionar empresa no dropdown
**And** dropdown de projetos atualiza via fetch para `/projects?company_id=X`
**And** apenas projetos daquela empresa aparecem
**And** se mudar empresa, lista de projetos atualiza novamente
**And** endpoint `/projects.json?company_id=X` retorna JSON de projetos
**And** interação é instantânea (< 300ms)

### Story 4.6: Criar Factories e Testes para Task e TaskItem

**Como** desenvolvedor
**Quero** testes completos para Task e TaskItem
**Para que** cálculos, validações e status automáticos sejam garantidos

**Acceptance Criteria:**

**Given** que RSpec está configurado
**When** crio factories para Task e TaskItem
**Then** factory Task possui: association :company, association :project
**And** factory Task possui: `name { Faker::Lorem.sentence }`, `start_date { Date.today }`
**And** factory Task possui: `estimated_hours { Faker::Number.decimal(l_digits: 1, r_digits: 2) }`
**And** factory TaskItem possui: association :task
**And** factory TaskItem possui: `start_time { '09:00' }`, `end_time { '10:30' }`
**And** testes confirmam validações de presence
**And** testes confirmam validação: project pertence a company
**And** testes confirmam cálculo correto de hours_worked em TaskItem
**And** testes confirmam recálculo automático de Task status
**And** testes confirmam Task não recalcula status quando 'delivered'
**And** testes confirmam cálculo de total_hours e calculated_value
**And** `bundle exec rspec spec/models/task_spec.rb` passa 100%
**And** `bundle exec rspec spec/models/task_item_spec.rb` passa 100%

---

## 📘 Especificação Técnica - Epic 4: Task Management System

**Data:** 2026-01-19
**Status:** Especificação Aprovada
**Padrão de Código:** INGLÊS (schemas, models, campos, métodos)
**Documentação:** PORTUGUÊS (textos explicativos, comentários)

---

### 📋 Visão Geral

Sistema de **gerenciamento de tarefas com tracking de tempo integrado**, substituindo o conceito original de TimeEntries (timesheet simples).

**Mudança Conceitual:**

**Original (TimeEntries):**
```
Companies → Projects → TimeEntries (registro simples de horas)
```

**Novo (Tasks + TaskItems):**
```
Companies → Projects → Tasks (tarefas gerenciáveis)
                        ├─ Status automático (Pending/Completed/Delivered)
                        ├─ Valores calculados (hourly_rate * hours)
                        ├─ Horas estimadas vs validadas
                        └─ TaskItems (registro granular de horas)
                            ├─ start_time/end_time
                            ├─ Cálculo automático de duração
                            └─ Status que atualiza Task pai
```

---

### 🗄️ Schema de Banco de Dados

#### Tabela: `tasks`

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_tasks.rb
class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true, if_not_exists: true
      t.references :project, null: false, foreign_key: true, if_not_exists: true
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false, default: 'pending'
      t.date :delivery_date
      t.decimal :estimated_hours, precision: 10, scale: 2, null: false
      t.decimal :validated_hours, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :tasks, :company_id, if_not_exists: true
    add_index :tasks, :project_id, if_not_exists: true
    add_index :tasks, :status, if_not_exists: true
    add_index :tasks, [:company_id, :project_id], if_not_exists: true
  end
end
```

**Campos:**
- `name` (string, obrigatório): Nome da tarefa
- `company_id` (integer, obrigatório): FK para companies
- `project_id` (integer, obrigatório): FK para projects
- `start_date` (date, obrigatório): Data de início (manual)
- `end_date` (date, opcional): Data de término (automática quando completed)
- `status` (string, obrigatório, default: 'pending'): Status da tarefa
- `delivery_date` (date, opcional): Data de entrega ao cliente (automática quando delivered)
- `estimated_hours` (decimal, obrigatório): Horas estimadas (manual)
- `validated_hours` (decimal, opcional): Horas reais (calculado)
- `notes` (text, opcional): Observações gerais

---

#### Tabela: `task_items`

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_task_items.rb
class CreateTaskItems < ActiveRecord::Migration[8.1]
  def change
    create_table :task_items, if_not_exists: true do |t|
      t.references :task, null: false, foreign_key: true, if_not_exists: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.decimal :hours_worked, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :task_items, :task_id, if_not_exists: true
    add_index :task_items, :status, if_not_exists: true
    add_index :task_items, [:task_id, :created_at], if_not_exists: true
  end
end
```

**Campos:**
- `task_id` (integer, obrigatório): FK para tasks
- `start_time` (time, obrigatório): Hora de início do trabalho
- `end_time` (time, obrigatório): Hora de término do trabalho
- `hours_worked` (decimal, obrigatório): Duração calculada (end_time - start_time)
- `status` (string, obrigatório, default: 'pending'): Status do item

---

### 🏗️ Models

#### Model: Task

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  # ============================================================================
  # ASSOCIAÇÕES
  # ============================================================================
  belongs_to :company
  belongs_to :project
  has_many :task_items, dependent: :destroy

  # ============================================================================
  # VALIDAÇÕES
  # ============================================================================
  validates :name, presence: true
  validates :company_id, presence: true
  validates :project_id, presence: true
  validates :start_date, presence: true
  validates :estimated_hours, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed delivered] }

  # Validação customizada: project deve pertencer à company
  validate :project_must_belong_to_company

  # ============================================================================
  # ENUMS
  # ============================================================================
  enum status: {
    pending: 'pending',
    completed: 'completed',
    delivered: 'delivered'
  }, _prefix: true

  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_save :update_end_date, if: :status_changed_to_completed?
  before_save :update_delivery_date, if: :status_changed_to_delivered?
  after_save :recalculate_validated_hours

  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }

  # ============================================================================
  # MÉTODOS PÚBLICOS
  # ============================================================================

  # Calcula total de horas trabalhadas (soma dos TaskItems)
  def total_hours
    task_items.sum(:hours_worked)
  end

  # Calcula valor da tarefa (company.hourly_rate * total_hours)
  def calculated_value
    company.hourly_rate * total_hours
  end

  # Recalcula status baseado no último TaskItem criado
  def recalculate_status!
    return if delivered? # Não recalcula se já está delivered (imutável)

    latest_item = task_items.order(created_at: :desc).first
    return unless latest_item

    new_status = latest_item.completed? ? 'completed' : 'pending'
    update_column(:status, new_status) if status != new_status
  end

  # ============================================================================
  # MÉTODOS PRIVADOS
  # ============================================================================
  private

  # Validação: project deve pertencer à company selecionada
  def project_must_belong_to_company
    return unless project.present? && company.present?

    if project.company_id != company_id
      errors.add(:project, "deve pertencer à empresa selecionada")
    end
  end

  # Callback: atualiza end_date quando muda para completed
  def status_changed_to_completed?
    status == 'completed' && status_changed?
  end

  def update_end_date
    self.end_date = Date.today
  end

  # Callback: atualiza delivery_date quando muda para delivered
  def status_changed_to_delivered?
    status == 'delivered' && status_changed?
  end

  def update_delivery_date
    self.delivery_date = Date.today
  end

  # Callback: recalcula validated_hours após cada save
  def recalculate_validated_hours
    update_column(:validated_hours, total_hours)
  end
end
```

---

#### Model: TaskItem

```ruby
# app/models/task_item.rb
class TaskItem < ApplicationRecord
  # ============================================================================
  # ASSOCIAÇÕES
  # ============================================================================
  belongs_to :task

  # ============================================================================
  # VALIDAÇÕES
  # ============================================================================
  validates :task_id, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed] }

  validate :end_time_after_start_time
  validate :task_must_not_be_delivered, on: [:create, :update]

  # ============================================================================
  # ENUMS
  # ============================================================================
  enum status: {
    pending: 'pending',
    completed: 'completed'
  }, _prefix: true

  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_save :calculate_hours_worked
  after_save :update_task_status
  after_destroy :update_task_status

  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_task, ->(task_id) { where(task_id: task_id) }
  scope :recent_first, -> { order(created_at: :desc) }

  # ============================================================================
  # MÉTODOS PRIVADOS
  # ============================================================================
  private

  # Validação: end_time deve ser posterior à start_time
  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior à hora inicial")
    end
  end

  # Validação: não pode modificar TaskItem de Task delivered
  def task_must_not_be_delivered
    return unless task.present?

    if task.delivered?
      errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    end
  end

  # Callback: calcula hours_worked automaticamente
  def calculate_hours_worked
    return unless start_time.present? && end_time.present?

    duration_in_seconds = (end_time - start_time)
    self.hours_worked = (duration_in_seconds / 3600.0).round(2)
  end

  # Callback: atualiza status da Task pai
  def update_task_status
    task.recalculate_status!
  end
end
```

---

### 📊 Regras de Negócio

#### 1. Relacionamento Task → Company + Project

**Regra:** Task pertence diretamente a Company E Project, com validação de consistência.

**Validação:**
```ruby
project.company_id == task.company_id
```

**Comportamento do Form:**
```javascript
// Quando seleciona Company no dropdown
onCompanyChange(company_id) {
  // Recarrega dropdown de Projects mostrando apenas:
  // Project.where(company_id: company_id).active.order(:name)
}
```

**Exemplo Válido:**
```ruby
company_a = Company.find(1)
project_x = Project.find(5) # project_x.company_id == 1

task = Task.create(
  name: "Implement Report",
  company: company_a,
  project: project_x  # ✅ Mesmo company_id
)
# ✅ SUCESSO
```

**Exemplo Inválido:**
```ruby
company_a = Company.find(1)
project_y = Project.find(10) # project_y.company_id == 2

task = Task.create(
  name: "Implement Report",
  company: company_a,
  project: project_y  # ❌ company_id diferente
)
# ❌ ERRO: "Project deve pertencer à empresa selecionada"
```

---

#### 2. Status Automático "Completed"

**Regra:** Task muda para "completed" quando o **último TaskItem CRIADO** (created_at DESC) estiver com status "completed".

**Algoritmo:**
```ruby
def recalculate_status!
  return if delivered? # Não recalcula se já está delivered

  latest_item = task_items.order(created_at: :desc).first
  return unless latest_item

  new_status = latest_item.completed? ? 'completed' : 'pending'
  update_column(:status, new_status) if status != new_status
end
```

**Exemplo 1: Finalizando Task**
```ruby
task = Task.create(name: "Implement Report", status: 'pending', ...)

# Cria 3 TaskItems
TaskItem.create(task: task, start_time: '08:00', end_time: '08:50', status: 'pending')
# created_at: 2026-01-19 09:00

TaskItem.create(task: task, start_time: '10:00', end_time: '10:45', status: 'pending')
# created_at: 2026-01-19 10:00

TaskItem.create(task: task, start_time: '13:00', end_time: '13:27', status: 'pending')
# created_at: 2026-01-19 11:00 ← ÚLTIMO CRIADO

# Task.status = 'pending' (porque último criado está pending)

# Finaliza o último item criado (11:00)
item_3 = TaskItem.last
item_3.update(status: 'completed')

# Task.status = 'completed' (porque último criado está completed)
```

**Exemplo 2: Reabertura de Task**
```ruby
task = Task.find(1) # Status: completed
# 3 TaskItems, todos completed (último criado: 11:00)

# Cria novo TaskItem pending
TaskItem.create(task: task, start_time: '15:00', end_time: '15:30', status: 'pending')
# created_at: 2026-01-19 12:00 ← NOVO ÚLTIMO CRIADO

# Task.status = 'pending' (porque último criado está pending)
```

---

#### 3. Status Manual "Delivered" (Imutável)

**Regra:** Status "delivered" é definido manualmente via botão/ícone e torna a Task **read-only**.

**Comportamento:**
```ruby
# Botão "Mark as Delivered"
def mark_as_delivered
  task.update!(
    status: 'delivered',
    delivery_date: Date.today
  )
end
```

**Restrições:**
```ruby
# Não pode criar novos TaskItems
TaskItem.create(task: task_delivered, ...)
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Não pode editar TaskItems existentes
task_item.update(status: 'completed')
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Não pode deletar TaskItems
task_item.destroy
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Status "delivered" é FINAL (não pode voltar para completed ou pending)
task_delivered.recalculate_status!
# → Não faz nada (return if delivered?)
```

**Fluxo de Status:**
```
pending ←→ completed → delivered (FINAL)
   ↑           ↑
   └───────────┘
   (automático via TaskItems)
```

---

#### 4. Campos de Data

**start_date: MANUAL**
```ruby
# Usuário define ao criar a Task
task = Task.create(
  name: "Implement Report",
  start_date: Date.new(2026, 1, 10),  # Manual
  ...
)
```

**end_date: AUTOMÁTICA**
```ruby
# Atualiza automaticamente quando status → completed
before_save :update_end_date, if: :status_changed_to_completed?

def update_end_date
  self.end_date = Date.today
end

# Exemplo:
task.update(status: 'completed')
# → task.end_date = Date.today (2026-01-19)
```

**delivery_date: AUTOMÁTICA**
```ruby
# Atualiza automaticamente quando status → delivered
before_save :update_delivery_date, if: :status_changed_to_delivered?

def update_delivery_date
  self.delivery_date = Date.today
end
```

---

#### 5. Cálculos Automáticos

**hours_worked (TaskItem):**
```ruby
# Calculado automaticamente antes de save
before_save :calculate_hours_worked

def calculate_hours_worked
  return unless start_time.present? && end_time.present?

  duration_in_seconds = (end_time - start_time)
  self.hours_worked = (duration_in_seconds / 3600.0).round(2)
end

# Exemplo:
TaskItem.create(start_time: '08:00', end_time: '10:30', ...)
# → hours_worked = 2.5
```

**validated_hours (Task):**
```ruby
# Atualiza após cada save
after_save :recalculate_validated_hours

def recalculate_validated_hours
  update_column(:validated_hours, total_hours)
end

def total_hours
  task_items.sum(:hours_worked)
end

# Exemplo:
task.task_items.sum(:hours_worked) # => 5.75
task.validated_hours # => 5.75 (atualizado automaticamente)
```

**calculated_value (Task):**
```ruby
# Método virtual (não persiste no banco)
def calculated_value
  company.hourly_rate * total_hours
end

# Exemplo:
task.company.hourly_rate # => 45.00
task.total_hours # => 5.75
task.calculated_value # => 258.75 (45.00 * 5.75)
```

---

### 🎯 Casos de Uso Completos

#### Caso de Uso 1: Criar Task e Registrar Horas

```ruby
# 1. Criar Task
company = Company.find_by(name: "Company A")
project = company.projects.find_by(name: "Project X")

task = Task.create!(
  name: "Implement Sales Report",
  company: company,
  project: project,
  start_date: Date.new(2026, 1, 10),
  estimated_hours: 8.0,
  status: 'pending'
)
# Status: pending
# end_date: nil
# validated_hours: 0.0
# calculated_value: 0.0

# 2. Registrar primeira hora de trabalho
TaskItem.create!(
  task: task,
  start_time: Time.parse('08:00'),
  end_time: Time.parse('09:30'),
  status: 'pending'
)
# hours_worked: 1.5 (calculado automaticamente)
# Task.status: pending (último item criado está pending)
# Task.validated_hours: 1.5
# Task.calculated_value: 67.50 (45.00 * 1.5)

# 3. Registrar segunda hora (já completed)
TaskItem.create!(
  task: task,
  start_time: Time.parse('10:00'),
  end_time: Time.parse('12:15'),
  status: 'completed'
)
# hours_worked: 2.25
# Task.status: completed (último item criado está completed)
# Task.end_date: 2026-01-19 (atualizado automaticamente)
# Task.validated_hours: 3.75 (1.5 + 2.25)
# Task.calculated_value: 168.75 (45.00 * 3.75)

# 4. Adicionar hora extra (reabre Task)
TaskItem.create!(
  task: task,
  start_time: Time.parse('14:00'),
  end_time: Time.parse('15:00'),
  status: 'pending'
)
# hours_worked: 1.0
# Task.status: pending (último item criado está pending)
# Task.validated_hours: 4.75 (1.5 + 2.25 + 1.0)
# Task.calculated_value: 213.75 (45.00 * 4.75)

# 5. Finalizar última hora
item_3 = TaskItem.last
item_3.update!(status: 'completed')
# Task.status: completed (último item criado está completed)
# Task.end_date: 2026-01-19 (atualizado novamente)

# 6. Marcar como Delivered
task.update!(status: 'delivered')
# Task.status: delivered
# Task.delivery_date: 2026-01-19
# Task agora é READ-ONLY

# 7. Tentar adicionar hora (ERRO)
TaskItem.create(task: task, ...)
# ❌ ActiveRecord::RecordInvalid:
#    "Não é possível modificar itens de tarefa já entregue"
```

---

### 🚨 Impacto em Epics 5-8

#### Epic 5: Visualização e Totalizadores
**Status:** ⚠️ **REVISAR PARCIAL**

**Mudanças:**
- Index deve mostrar Tasks (não TimeEntries)
- Totalizadores agora são por Task (não por entrada)
- ViewComponent precisa mostrar TaskItems agregados
- Turbo Streams para atualizar Task + TaskItems

**Estimativa:** +2-3 stories adicionais para lidar com agregação

---

#### Epic 6: Filtros Dinâmicos
**Status:** ⚠️ **REVISAR PARCIAL**

**Mudanças:**
- Filtros por company E project (antes só project)
- Status agora tem 3 valores (pending/completed/delivered)
- Recalcular totalizadores por Task (não por entry)

**Estimativa:** +1-2 stories adicionais

---

#### Epic 7: Edição e Correção de Entradas
**Status:** 🚨 **REFAZER COMPLETO**

**Mudanças:**
- Editar Task (campos adicionais: start_date, estimated_hours, notes)
- Editar TaskItems (start_time, end_time)
- Validação de Task delivered (read-only)
- Destroy precisa considerar status "delivered"
- System tests para fluxo Task → TaskItems → Delivered

**Estimativa:** Epic 7 passará de 3 stories para ~5-6 stories

---

#### Epic 8: Responsividade e Experiência Mobile
**Status:** ⚠️ **REVISAR LEVE**

**Mudanças:**
- Form de Task mais complexo (company + project dropdowns)
- Lista de TaskItems por Task
- Botão "Mark as Delivered" mobile-friendly

**Estimativa:** +1 story adicional

---

### 📊 Resumo de Impacto

| Epic | Status Original | Status Novo | Stories Original | Stories Estimado | Impacto |
|------|----------------|-------------|------------------|------------------|---------|
| Epic 4 | 6 stories | 🚨 REFEITO | 6 | 6 | **Novo design** |
| Epic 5 | 5 stories | ⚠️ REVISAR | 5 | 7-8 | +40-60% |
| Epic 6 | 4 stories | ⚠️ REVISAR | 4 | 5-6 | +25-50% |
| Epic 7 | 3 stories | 🚨 REFAZER | 3 | 5-6 | **+67-100%** |
| Epic 8 | 4 stories | ⚠️ REVISAR | 4 | 5 | +25% |
| **TOTAL** | **22 stories** | - | **22** | **28-33** | **+27-50%** |

---

## Epic 5: Visualização e Totalizadores

**Objetivo:** Igor pode ver todas as suas entradas e totais calculados automaticamente

### Story 5.1: Implementar Index de TimeEntries com Eager Loading

**Como** Igor
**Quero** visualizar lista de entradas do mês atual
**Para que** eu veja todos os registros rapidamente

**Acceptance Criteria:**

**Given** que CRUD de TimeEntries existe
**When** implemento action index em TimeEntriesController
**Then** rota `GET /time_entries` exibe entradas do mês atual
**And** query usa `TimeEntry.includes(:company, :project).where(user: current_user, date: Date.current.all_month)`
**And** Bullet não detecta N+1 queries
**And** lista exibe: date, start_time, end_time, duration (formatado), company.name, project.name, activity, status, calculated_value
**And** carregamento completo < 2 segundos (NFR3)
**And** ordenação: mais recentes primeiro

### Story 5.2: Criar ViewComponent para TimeEntry Card

**Como** desenvolvedor
**Quero** componente reutilizável para exibir TimeEntry
**Para que** UI seja consistente e testável

**Acceptance Criteria:**

**Given** que ViewComponent gem está instalada
**When** crio TimeEntryCardComponent
**Then** component recebe `entry:` como parâmetro
**And** template exibe todos os campos de forma organizada
**And** status tem badge colorido: pending=yellow, completed=green, reopened=orange, delivered=blue
**And** valor monetário é destacado em verde
**And** links de "Editar" e "Deletar" aparecem no card
**And** component é testável isoladamente
**And** `bundle exec rspec spec/components/time_entry_card_component_spec.rb` passa 100%

### Story 5.3: Implementar Totalizadores Dinâmicos (Total do Dia)

**Como** Igor
**Quero** ver total de horas trabalhadas no dia atual
**Para que** eu acompanhe meu progresso diário

**Acceptance Criteria:**

**Given** que index de TimeEntries existe
**When** adiciono método de classe `TimeEntry.total_hours_for_day(date, user)`
**Then** método usa `SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600)`
**And** retorna total de horas em decimal
**And** dashboard exibe: "Total do dia: X.Xh"
**And** total atualiza automaticamente após criar nova entrada via Turbo Stream
**And** cálculo é instantâneo (< 500ms)

### Story 5.4: Implementar Totalizadores por Empresa no Mês

**Como** Igor
**Quero** ver total de horas e valor por empresa no mês
**Para que** eu saiba quanto trabalhar para cada cliente

**Acceptance Criteria:**

**Given** que total do dia existe
**When** adiciono método `TimeEntry.total_hours_by_company(month, year, user)`
**Then** método usa `GROUP BY company_id` com `SUM(duration_minutes)`
**And** retorna hash: `{ company => { hours: X, value: Y } }`
**And** dashboard exibe tabela: empresa, horas totais, valor total
**And** cada linha mostra: company.name, total de horas formatado, R$ total
**And** query usa eager loading para evitar N+1
**And** carregamento < 1 segundo

### Story 5.5: Configurar Turbo Streams para Atualização em Tempo Real

**Como** Igor
**Quero** que totais atualizem automaticamente ao criar/editar entradas
**Para que** eu sempre veja dados atualizados

**Acceptance Criteria:**

**Given** que totalizadores existem
**When** configuro Turbo Streams no TimeEntry model
**Then** `after_commit :broadcast_totals_update`
**And** broadcast atualiza target `daily_totals`
**And** broadcast atualiza target `monthly_totals`
**And** ao criar nova entrada, totais atualizam sem refresh manual
**And** feedback visual é instantâneo (< 500ms, NFR5)

---

## Epic 6: Filtros Dinâmicos

**Objetivo:** Igor pode filtrar entradas por empresa, projeto, status e data para análises específicas

### Story 6.1: Implementar Filtros por Empresa e Projeto

**Como** Igor
**Quero** filtrar entradas por empresa ou projeto
**Para que** eu veja apenas dados relevantes

**Acceptance Criteria:**

**Given** que index de TimeEntries existe
**When** adiciono formulário de filtros na view
**Then** formulário possui: company_id (select), project_id (select)
**And** dropdowns têm opção "Todas" como padrão
**And** ao selecionar empresa, index filtra: `where(company_id: params[:company_id])`
**And** ao selecionar projeto, index filtra: `where(project_id: params[:project_id])`
**And** filtros aplicam em < 1 segundo (NFR4)
**And** URL reflete filtros: `/time_entries?company_id=1&project_id=2`

### Story 6.2: Implementar Filtros por Status e Data/Período

**Como** Igor
**Quero** filtrar por status e períodos de tempo
**Para que** eu analise dados históricos

**Acceptance Criteria:**

**Given** que filtros de empresa/projeto existem
**When** adiciono filtros: status (select), date_from (date), date_to (date)
**Then** status dropdown possui: "Todos", "Pendente", "Finalizado", "Reaberto", "Entregue"
**And** filtro de data permite range: `where(date: params[:date_from]..params[:date_to])`
**And** filtros são combinados com AND lógico
**And** ao aplicar múltiplos filtros, query permanece otimizada
**And** filtros aplicam instantaneamente (< 1s)

### Story 6.3: Recalcular Totalizadores Conforme Filtros Aplicados

**Como** Igor
**Quero** que totalizadores reflitam apenas entradas filtradas
**Para que** análises sejam precisas

**Acceptance Criteria:**

**Given** que filtros estão implementados
**When** aplico qualquer filtro
**Then** totalizadores recalculam baseados nas entradas filtradas
**And** "Total geral" exibe soma apenas das entradas visíveis
**And** "Total por empresa" agrupa apenas entradas filtradas
**And** recalculo é instantâneo (< 500ms)
**And** mensagem indica: "Mostrando X entradas (filtrado)"

### Story 6.4: Criar Stimulus Controller para Filtros com Turbo Frames

**Como** Igor
**Quero** que filtros funcionem sem reload de página
**Para que** experiência seja fluida

**Acceptance Criteria:**

**Given** que filtros de backend existem
**When** crio `filter_controller.js` em Stimulus
**Then** formulário de filtros está dentro de `<turbo-frame id="time_entries_list">`
**And** ao mudar qualquer filtro, submit automático via Turbo Frame
**And** apenas lista de entradas recarrega, header/sidebar permanecem
**And** URL atualiza com query params
**And** loading state é exibido durante fetch
**And** transição é suave (< 1 segundo, NFR4)

---

## Epic 7: Edição e Correção de Entradas

**Objetivo:** Igor pode corrigir erros em entradas registradas sem medo de "quebrar" dados

### Story 7.1: Implementar Edit/Update de TimeEntries

**Como** Igor
**Quero** editar entradas existentes
**Para que** eu possa corrigir erros

**Acceptance Criteria:**

**Given** que TimeEntries estão sendo criadas
**When** adiciono actions edit, update ao TimeEntriesController
**Then** rota `GET /time_entries/:id/edit` exibe formulário preenchido
**And** formulário permite editar todos os campos: date, times, company, project, activity, status
**And** validações tripla camada aplicam na edição
**And** ao salvar, cálculos são refeitos via Calculable concern
**And** rota `PATCH /time_entries/:id` atualiza entrada
**And** flash message: "Entrada atualizada com sucesso"
**And** totalizadores recalculam automaticamente via Turbo Stream
**And** edição preserva integridade referencial

### Story 7.2: Implementar Destroy de TimeEntries com Confirmação

**Como** Igor
**Quero** deletar entradas incorretas
**Para que** dados sejam precisos

**Acceptance Criteria:**

**Given** que TimeEntries existem
**When** adiciono action destroy ao TimeEntriesController
**Then** link "Deletar" possui confirmação: "Tem certeza?" via Turbo
**And** rota `DELETE /time_entries/:id` deleta entrada permanentemente
**And** flash message: "Entrada deletada com sucesso"
**And** totalizadores recalculam via Turbo Stream
**And** entrada removida da lista sem reload de página
**And** se houver erro, mensagem clara é exibida

### Story 7.3: Criar Testes de System para Fluxo Completo

**Como** desenvolvedor
**Quero** testes end-to-end do fluxo de CRUD
**Para que** funcionalidade completa seja garantida

**Acceptance Criteria:**

**Given** que RSpec System está configurado
**When** crio spec/system/time_entries_spec.rb
**Then** teste simula: login → criar empresa → criar projeto → criar entrada → editar entrada → deletar entrada
**And** teste confirma validações client-side funcionam
**And** teste confirma totalizadores atualizam
**And** teste confirma fluxo completo funciona sem erros
**And** `bundle exec rspec spec/system/time_entries_spec.rb` passa 100%

---

## Epic 8: Responsividade e Experiência Mobile

**Objetivo:** Igor pode usar o sistema em qualquer dispositivo (desktop, tablet, mobile)

### Story 8.1: Implementar Mobile-First com Tailwind Breakpoints

**Como** Igor
**Quero** interface otimizada para mobile
**Para que** eu possa registrar horas pelo celular

**Acceptance Criteria:**

**Given** que Tailwind CSS está configurado
**When** implemento layouts mobile-first
**Then** formulários usam classes Tailwind: `sm:`, `md:`, `lg:`
**And** breakpoints: mobile < 768px, tablet 768-1023px, desktop ≥ 1024px
**And** forms em mobile ocupam largura completa
**And** forms em desktop têm max-width e centralização
**And** botões em mobile são touch-friendly (min-height: 44px)
**And** dropdowns em mobile são otimizados para touch

### Story 8.2: Otimizar TimeEntry Form para Mobile

**Como** Igor
**Quero** formulário de entrada rápido no mobile
**Para que** registro continue sendo ~30 segundos

**Acceptance Criteria:**

**Given** que mobile-first está implementado
**When** otimizo formulário de TimeEntry para mobile
**Then** inputs de data/hora usam type correto: `type="date"`, `type="time"`
**And** teclado mobile abre automaticamente com tipo correto
**And** labels são claras e visíveis
**And** textarea de activity tem altura adequada para touch
**And** botão submit é destacado e grande o suficiente
**And** validações client-side funcionam perfeitamente em mobile

### Story 8.3: Garantir Acessibilidade WCAG Nível A

**Como** Igor
**Quero** navegação por teclado funcional
**Para que** acessibilidade básica seja garantida

**Acceptance Criteria:**

**Given** que interface mobile está otimizada
**When** implemento padrões de acessibilidade
**Then** todos os inputs têm `<label>` associados corretamente
**And** navegação por Tab funciona em ordem lógica
**And** Enter submete formulários
**And** Esc fecha modals/dropdowns
**And** contraste de cores é mínimo 4.5:1 (NFR21)
**And** HTML semântico: `<main>`, `<nav>`, `<section>`, `<button>` (NFR19)
**And** mensagens de erro são claras e associadas aos campos

### Story 8.4: Testar Responsividade em Múltiplos Dispositivos

**Como** desenvolvedor
**Quero** confirmar funcionalidade em todos os breakpoints
**Para que** todos os dispositivos sejam suportados

**Acceptance Criteria:**

**Given** que mobile-first está implementado
**When** testo em Chrome DevTools device emulation
**Then** testo em: iPhone SE (375px), iPad (768px), Desktop (1024px+)
**And** formulário de registro funciona perfeitamente em todos
**And** lista de entradas é legível em todos
**And** totalizadores são visíveis em todos
**And** filtros funcionam em mobile (dropdown otimizado)
**And** todos os navegadores suportados: Chrome, Firefox, Safari, Edge (últimas 2 versões, NFR9)
