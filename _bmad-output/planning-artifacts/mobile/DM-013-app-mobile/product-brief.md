# Product Brief — DM-013: App Mobile (Cronos POC Mobile)

## Contexto

O Cronos POC já existe como web (Rails + Hotwire) em produção, usado por Igor e colegas para registrar tarefas e horas trabalhadas. O acesso hoje exige abrir o navegador e navegar até a URL do sistema.

## Problema

Abrir o navegador, digitar/lembrar a URL e navegar até o dashboard é uma fricção perceptível para uma ação que devia ser rápida (registrar uma tarefa ou lançar horas). Não há um app nativo com acesso de um toque (ícone na home screen).

## Objetivo

Criar uma versão mobile nativa (React Native + Expo) que reduza a fricção de acesso e melhore a performance percebida, reaproveitando os mesmos dados e regras de negócio do backend web — sem adicionar funcionalidades novas além do que a web já oferece.

## Usuários

- Mesmo público da web: profissionais que registram tarefas e horas trabalhadas diariamente.

## Escopo

**Nesta entrega (POC mobile via Expo Go):**
- Login via Google OAuth (reaproveitando conta já usada na web)
- Sessão persistente entre aberturas do app (sem re-login constante)
- Dashboard com KPIs/totalizadores equivalentes aos da web
- Lista de tarefas do usuário
- Criação de tarefa a partir do dashboard
- Registro de horas (TaskItem) a partir do dashboard
- Nova API JSON (`/api/v1/`) autenticada por token, isolada dos controllers Hotwire existentes

**Fora de escopo (por ora):**
- Publicação em loja (Google Play/App Store) — só após validação via Expo Go
- Qualquer funcionalidade não existente na web (o app não deve superar a web em escopo, só em conveniência de acesso)
- Alterações nos controllers/views/specs da web existentes

## Métrica de sucesso

- Usuário consegue abrir o app, ver o dashboard e criar tarefa/lançar hora sem passar pelo navegador, em menos tempo do que levaria pela web.

## Riscos e considerações técnicas (para arquitetura)

- Backend hoje não tem API JSON nem autenticação por token — é capacidade nova (ver `architecture-mobile.md`).
- Isolamento multi-tenant da web (404 em vez de 403 para acesso cruzado) precisa ser replicado na API.

## Próximos passos

1. PRD: `../prd-mobile.md`
2. Arquitetura: `../architecture-mobile.md`
3. Epics/Stories: `../epics-mobile.md`
