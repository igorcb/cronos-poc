---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain-skipped', 'step-06-innovation-skipped', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete']
classification:
  projectType: mobile_app
  domain: general
  complexity: low
  projectContext: brownfield-backend/greenfield-client
vision:
  summary: "App mobile nativo para criar tarefas e registrar horas direto do celular, reduzindo fricção de acesso (1 toque vs abrir browser + URL) e com melhor performance percebida que a web mobile"
  differentiator: "Conveniência de acesso (ícone na home screen) + performance nativa"
  coreInsight: "O fluxo funcional já existe na web; o app ataca fricção de acesso e responsividade percebida, não recursos novos"
  whyNow: "Demanda real de usuários (amigos pediram) e baixo risco por ser POC"
inputDocuments: ['architecture.md']
workflowType: 'prd'
project_name: 'cronos-poc-mobile'
user_name: 'Igor'
date: '2026-07-07'
---

# Product Requirements Document - Cronos POC Mobile

**Author:** Igor
**Date:** 2026-07-07

## Executive Summary

O **Cronos POC Mobile** é um app nativo (iOS + Android, React Native + Expo) que permite aos usuários do Cronos-POC criar tarefas e registrar horas trabalhadas diretamente do celular. É uma POC — o objetivo não é replicar 100% da web, mas validar o fluxo essencial de timesheet num app instalável na tela inicial.

O público é o mesmo da web: profissionais que registram horas trabalhadas por empresa/projeto/tarefa. O gatilho direto foi demanda real de usuários que pediram um app.

### What Makes This Special

O diferencial não está em recursos novos — o fluxo funcional já existe na web responsiva. O app ataca dois atritos que a web não resolve: **fricção de acesso** (ícone na home screen vs. abrir browser e navegar até a URL) e **performance percebida** (abertura instantânea e interações nativas mais fluidas que uma página web rodando no browser mobile). A aposta é que reduzir esses dois atritos aumenta a frequência de uso — registrar horas se torna um gesto rápido, não uma tarefa que exige abrir o navegador.

## Project Classification

- **Tipo de projeto:** Mobile App (nativo, cross-platform via React Native/Expo)
- **Domínio:** Geral (timesheet/produtividade) — sem exigências regulatórias específicas
- **Complexidade:** Baixa
- **Contexto:** Brownfield no backend (reaproveita a API/dados do Cronos-POC Rails existente) + Greenfield no client mobile (app nativo não existe ainda)

## Success Criteria

### User Success
Usuário abre o app e chega direto ao dashboard (sem fricção de login repetido — sessão persistida). A partir do dashboard, consegue criar uma tarefa ou lançar horas trabalhadas em menos de 15 segundos, do toque no ícone até a ação concluída.

### Business Success
A POC é considerada bem-sucedida se os usuários que pediram o app (early adopters) o usam de forma **recorrente** nas primeiras semanas — não como teste único e abandono. Isso sinaliza se vale investir em evolução para produção ou encerrar a iniciativa.

### Technical Success
App funciona de forma estável em iOS e Android via Expo, com deploy de atualizações simples via Expo Updates (OTA), sem exigir republish em loja a cada ajuste pequeno durante a fase de POC.

### Measurable Outcomes
- Tempo do abrir-app até dashboard carregado: instantâneo (sem tela de login repetida)
- Tempo de criar tarefa ou lançar hora: < 15 segundos
- Uso recorrente pelos early adopters nas primeiras semanas pós-lançamento

## Product Scope

### MVP - Minimum Viable Product
- Login via OAuth Google (reaproveita autenticação existente do backend)
- Dashboard como tela principal, replicando KPIs/totalizadores da web
- Criar tarefa a partir do dashboard
- Lançar horas trabalhadas (TaskItem) a partir do dashboard

### Growth Features (Post-MVP)
- Edição/exclusão de tarefas e horas pelo app
- Filtros dinâmicos (mesmo padrão da web)
- Gestão de empresas/projetos pelo app
- Notificações push (lembrete de registrar horas)

### Vision (Future)
- Registro offline com sincronização posterior
- Widget de tela inicial para lançar hora rápido
- Login biométrico

## User Journeys

### Jornada 1: Profissional lança horas no fim do dia (caminho feliz)

**Personagem:** Igor, consultor que atende 3 empresas diferentes, já usa o Cronos-POC na web.

**Cena de abertura:** É 18h, Igor terminou de trabalhar numa tarefa e está saindo do escritório do cliente. Ele pega o celular, sem vontade de abrir o navegador e navegar até a URL do Cronos-POC.

**Ação ascendente:** Ele toca no ícone do app na tela inicial. O app abre direto no dashboard — sem pedir login novamente (sessão já estava ativa). Ele vê os KPIs do dia/mês, exatamente como na web. Toca em "lançar horas", seleciona a tarefa em andamento, preenche horário de início/fim.

**Clímax:** Em poucos toques, a hora é registrada e o dashboard atualiza o total do dia na hora — sem reload, sem espera.

**Resolução:** Igor guarda o celular, tranquilo sabendo que o registro está feito e auditável, sem ter esperado chegar em casa e abrir o notebook.

**Capacidades reveladas:** login persistente/sessão longa, dashboard com KPIs, fluxo de criação de TaskItem, atualização em tempo real dos totalizadores.

### Jornada 2: Profissional cria uma tarefa nova pelo celular (caso de borda)

**Personagem:** Igor de novo, mas agora numa reunião com um cliente novo que acabou de fechar um projeto.

**Situação:** Não existe ainda uma Task cadastrada pra esse trabalho. Ele precisa criar a tarefa ali, na hora, pelo celular — não tem notebook à mão.

**Ação ascendente:** No dashboard, toca em "nova tarefa". Preenche nome, código, empresa/projeto associado. Salva.

**Ponto de decisão/erro:** E se a empresa/projeto ainda não existir? Nesse MVP, a gestão de empresas/projetos fica de fora do mobile (é Growth) — então Igor só consegue criar tarefas em projetos que já existem, criados previamente pela web.

**Resolução:** A tarefa nova aparece no dashboard imediatamente, pronta para receber lançamentos de hora futuros.

**Capacidades reveladas:** fluxo de criação de Task no mobile, seleção de empresa/projeto existentes (sem criar novos), validação de que a tarefa pertence ao usuário autenticado (mesma regra multi-tenant da web).

### Journey Requirements Summary

- Sessão persistente (evitar login repetido) — requer estratégia de auth mobile-friendly (token, não cookie de sessão como na web)
- Dashboard mobile replicando KPIs da web, com fetch/refresh de dados via API
- Formulário de criação de Task (reaproveitando empresas/projetos já existentes — sem CRUD de empresa/projeto no MVP)
- Formulário de criação de TaskItem (registro de hora) vinculado a uma Task existente
- Atualização em tempo real (ou refresh manual) dos totalizadores após ação

## Mobile App Specific Requirements

### Project-Type Overview
App cross-platform nativo (React Native + Expo) para iOS e Android, cobrindo o fluxo essencial de timesheet do Cronos-POC.

### Technical Architecture Considerations
- **Plataforma:** React Native + Expo (gerenciado), cross-platform iOS/Android a partir de um único codebase
- **Modo offline:** Fora do MVP — app requer conexão para funcionar (registro offline fica como item de Vision futura)
- **Notificações push:** Fora do MVP (Growth)
- **Recursos de dispositivo:** Nenhum recurso nativo específico necessário no MVP (sem câmera, GPS ou biometria)

### Distribution Strategy
- **Fase de validação (POC):** Distribuição via **Expo Go** — app roda dentro do app Expo Go durante todo o ciclo de validação, sem necessidade de build nativo, conta de desenvolvedor paga ou review de loja
- **Pós-validação:** Se a POC validar (early adopters usam de forma recorrente), publicação na **Google Play Store** (Android primeiro). Publicação na App Store (iOS) fica como decisão futura, fora deste PRD.

### Implementation Considerations
- Como não há modo offline nem device features no MVP, a superfície de complexidade técnica fica concentrada em: autenticação mobile-friendly (token-based, não cookie de sessão), consumo de API JSON (a ser criada no backend Rails, hoje inexistente) e UI do dashboard/formulários em React Native.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy
**Abordagem MVP:** Problem-solving MVP — validar se resolver a fricção de acesso (app vs. browser) realmente aumenta o uso, com o menor conjunto de telas possível.
**Requisitos de recursos:** 1 dev, sem equipe dedicada — típico de POC.

### MVP Feature Set (Phase 1)
**Jornadas principais suportadas:** Jornada 1 (lançar horas) e Jornada 2 (criar tarefa), ambas a partir do dashboard.
**Capacidades essenciais:**
- Login OAuth Google com sessão persistente (token-based)
- API JSON no backend Rails (não existe hoje — pré-requisito técnico)
- Dashboard mobile com KPIs
- Criar tarefa (empresa/projeto pré-existentes)
- Lançar hora (TaskItem)
- Distribuição via Expo Go

### Post-MVP Features

**Phase 2 (Growth):**
- Editar/excluir tarefas e horas
- Filtros dinâmicos
- Gestão de empresas/projetos
- Notificações push
- Publicação na Google Play Store

**Phase 3 (Expansion):**
- Registro offline com sync
- Widget de tela inicial
- Login biométrico
- Publicação na App Store

### Risk Mitigation Strategy
**Risco técnico (o maior):** o backend Rails hoje é 100% Hotwire, sem API JSON nem auth por token — isso é trabalho novo, não reaproveitamento puro. Mitigação: escopar a criação da API como parte explícita do MVP (não é "grátis" por já existir o backend).
**Risco de mercado:** POC pode não gerar uso recorrente mesmo resolvendo a fricção. Mitigação: já temos early adopters reais (os amigos que pediram) — validação rápida com usuários reais, não hipotéticos.
**Risco de recursos:** dev único. Mitigação: escopo deliberadamente mínimo (4 capacidades), sem features de "Growth" no caminho crítico.

## Functional Requirements

### Authentication
- FR1: Usuário pode autenticar-se no app via Google OAuth
- FR2: Usuário permanece autenticado entre sessões do app, sem precisar logar novamente a cada abertura
- FR3: Usuário pode encerrar sessão (logout) explicitamente

### Dashboard
- FR4: Usuário visualiza, ao abrir o app, um dashboard com os totalizadores/KPIs de horas e valores (diário/mensal), equivalente ao da web
- FR5: Usuário visualiza a lista de tarefas associadas às suas empresas/projetos

### Task Management
- FR6: Usuário pode criar uma nova tarefa (Task) selecionando uma empresa e projeto já existentes
- FR7: Usuário visualiza os dados de uma tarefa (código, nome, status) a partir do dashboard

### Time Tracking
- FR8: Usuário pode registrar horas trabalhadas (TaskItem) vinculadas a uma tarefa existente, informando início/fim ou duração
- FR9: Usuário visualiza a atualização dos totalizadores do dashboard imediatamente após registrar horas

### Backend Integration
- FR10: Sistema expõe uma API JSON autenticada por token para consumo do app mobile (capacidade nova no backend Rails, hoje inexistente)
- FR11: Sistema aplica as mesmas regras de isolamento multi-tenant (por usuário) já usadas na web, também via API

## Non-Functional Requirements

### Performance
- Abertura do app até o dashboard carregado: percebida como instantânea (sem tela de loading de login a cada abertura)
- Ações de criar tarefa/lançar hora: completam em menos de 15 segundos do toque no ícone até a confirmação
- Chamadas à API respondem em tempo que não bloqueie a interação do usuário (sem UI travada aguardando rede)

### Security
- Autenticação por token (não cookie), com expiração/renovação adequada para uso mobile
- API aplica o mesmo isolamento multi-tenant por usuário já usado na web (nenhum usuário acessa dados de outro usuário)
- Comunicação entre app e backend via HTTPS
