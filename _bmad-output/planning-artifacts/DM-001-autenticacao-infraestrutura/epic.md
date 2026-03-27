# Epic DM-001: Autenticação & Infraestrutura

**Domínio:** DM-001-autenticacao-infraestrutura
**Tipo:** Transversal / Técnico
**Status:** Concluído
**Prioridade:** Crítica (fundação de todos os domínios)

## Objetivo

Estabelecer a fundação técnica completa do projeto — Rails 8, Docker, PostgreSQL, ferramentas de qualidade, e autenticação single-user — para que todos os domínios subsequentes possam ser desenvolvidos sobre uma base sólida e padronizada.

## Valor de Negócio

Sem este épico, nenhuma funcionalidade de produto existe. É o alicerce que garante:
- Ambiente de desenvolvimento reproduzível (Docker)
- Qualidade de código desde o primeiro commit (RSpec, Rubocop, Bullet)
- Segurança de acesso (autenticação obrigatória)
- Base visual consistente (Tailwind + layout padrão)

## Dependências

- **Predecessores:** Nenhum (primeiro épico)
- **Sucessores:** Todos os domínios (DM-002 a DM-007)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Framework | Rails 8.1.1 | Produtividade, convenção, Hotwire nativo |
| Banco | PostgreSQL 16 | Integridade referencial, constraints, performance |
| Frontend | Hotwire (Turbo + Stimulus) | Sem SPA, menor complexidade, server-rendered |
| CSS | Tailwind CSS | Utility-first, responsivo, produtivo |
| Testes | RSpec + FactoryBot | Expressividade, maturidade do ecossistema |
| Auth | Rails 8 Generator | Session-based, sem gem extra, built-in |
| Container | Docker Compose | Reproduzível, web + db isolados |

## Critérios de Aceite do Épico

- [ ] `docker-compose up` sobe web + db sem erros
- [ ] `bundle exec rspec` executa com 0 failures
- [ ] `bundle exec rubocop` executa sem erros críticos
- [ ] Login com credenciais do seed funciona
- [ ] Rota `/signup` redireciona para `/login`
- [ ] Todas as rotas exigem autenticação
- [ ] Layout base com Tailwind renderiza corretamente
- [ ] `master.key` está no `.gitignore`

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-inicializar-projeto-rails-com-starter-template.md` | Inicializar Projeto Rails com Starter Template |
| 002 | `002-configurar-docker-e-docker-compose.md` | Configurar Docker e Docker Compose |
| 003 | `003-configurar-rspec-e-factories.md` | Configurar RSpec e Factories |
| 004 | `004-configurar-code-quality-tools.md` | Configurar Code Quality Tools |
| 005 | `005-implementar-autenticacao-single-user-com-rails-8-generator.md` | Implementar Autenticação Single-User |
| 006 | `006-desabilitar-signup-publico-e-criar-seed-de-usuario-admin.md` | Desabilitar Signup e Criar Seed Admin |
| 007 | `007-configurar-rails-credentials-para-secrets.md` | Configurar Rails Credentials |
| 008 | `008-implementar-ui-base-com-tailwind.md` | Implementar UI Base com Tailwind |

## Requisitos Rastreados

- ARQ1-ARQ9, ARQ10-ARQ16, ARQ28-ARQ33
- NFR14, NFR15, NFR16, NFR17
