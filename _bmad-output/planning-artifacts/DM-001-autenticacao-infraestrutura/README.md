# DM-001: Autenticação & Infraestrutura

**Domínio:** Transversal / Técnico
**Epic Relacionado:** Epic 1
**Status:** Concluído

## Descrição

Domínio responsável pelo setup inicial do projeto, containerização, ferramentas de qualidade de código, e autenticação single-user. Fornece a base técnica sobre a qual todos os outros domínios são construídos.

## Entidades

| Entidade | Tabela | Descrição |
|----------|--------|-----------|
| User | `users` | Usuário do sistema (single-user via seed) |
| Session | `sessions` | Sessões de autenticação |

## Regras de Negócio

1. **Single-User:** Sistema permite apenas um usuário, criado via seed com `ENV['ADMIN_EMAIL']` e `ENV['ADMIN_PASSWORD']`
2. **Signup Desabilitado:** Rota `/signup` redireciona para `/login` com mensagem de erro
3. **Autenticação Obrigatória:** Todas as rotas (exceto login) exigem autenticação via `before_action :require_authentication`
4. **Session-Based:** Autenticação via cookies de sessão (não JWT)
5. **Secrets:** Credenciais armazenadas via Rails Credentials (`config/credentials.yml.enc`)

## Stack Tecnológico

- **Rails 8.1.1** com Ruby 3.4.8
- **PostgreSQL 16** como banco de dados
- **Docker + Docker Compose** para containerização
- **Hotwire (Turbo + Stimulus)** para interatividade frontend
- **Tailwind CSS** para estilização
- **RSpec** + FactoryBot + Faker + Shoulda Matchers para testes
- **Rubocop** + Bullet + Annotate para qualidade de código

## Requisitos Cobertos

### Arquiteturais
- ARQ1-ARQ9: Setup Rails/Docker
- ARQ10-ARQ16: Testes e qualidade
- ARQ28-ARQ33: Autenticação

### Não-Funcionais
- NFR14: Autenticação obrigatória
- NFR15: Proteção CSRF
- NFR16: Sanitização de inputs
- NFR17: HTTPS obrigatório

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 1.1 | Inicializar Projeto Rails com Starter Template | Concluído |
| 1.2 | Configurar Docker e Docker Compose | Concluído |
| 1.3 | Configurar RSpec e Factories | Concluído |
| 1.4 | Configurar Code Quality Tools | Concluído |
| 1.5 | Implementar Autenticação Single-User com Rails 8 Generator | Concluído |
| 1.6 | Desabilitar Signup Público e Criar Seed de Usuário Admin | Concluído |
| 1.7 | Configurar Rails Credentials para Secrets | Concluído |
| 1.8 | Implementar UI Base com Tailwind | Concluído |
