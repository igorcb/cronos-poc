---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-03-success', 'step-04-journeys', 'step-07-project-type']
inputDocuments: []
workflowType: 'prd'
lastStep: 7
briefCount: 0
researchCount: 0
brainstormingCount: 0
projectDocsCount: 0
---

# Product Requirements Document - cronos-poc

**Author:** Igor
**Date:** 2025-12-26

## Executive Summary

O **Cronos POC** é um sistema web de timesheet desenvolvido para resolver a dificuldade de profissionais que trabalham para múltiplas empresas em manter registros confiáveis, precisos e facilmente acessíveis de suas horas trabalhadas.

**Visão do Produto:**
Substituir planilhas Excel manuais por uma aplicação web responsiva que garante precisão nos cálculos, oferece visibilidade clara sobre distribuição de tempo, e acelera o processo de registro de horas. O sistema captura horários de início e fim, associa cada entrada a uma empresa e projeto específico, calcula automaticamente o tempo trabalhado e valores monetários, e organiza essas informações de forma que profissionais possam comprovar suas horas trabalhadas de maneira confiável.

**Fase Atual:** Ferramenta pessoal para um desenvolvedor que trabalha simultaneamente para múltiplas empresas, com necessidade de consolidar horas mensais para faturamento.

**Visão Futura:** Produto SaaS disponível para profissionais autônomos e consultores que precisam rastrear tempo de forma profissional.

### O Que Torna Isso Especial

O Cronos POC se diferencia de planilhas tradicionais em três pilares fundamentais:

**1. Confiabilidade e Precisão**
- Cálculos automáticos garantidos sem risco de fórmulas incorretas ou células não copiadas
- Estrutura de dados consistente que elimina possibilidade de "bagunçar" o formato
- Histórico auditável e confiável para comprovar horas trabalhadas perante empresas contratantes

**2. Visibilidade Clara**
- Visualização rápida de totais por empresa, projeto e período
- Identificação de padrões: onde o tempo está sendo investido
- Dados prontos para faturamento sem necessidade de manipulação manual

**3. Velocidade no Registro**
- Processo de entrada mais rápido que navegar em planilhas
- Foco na tarefa (registrar tempo) sem se preocupar com formatação ou manutenção de fórmulas

**Momento de Valor:** Quando o profissional fecha o mês e em segundos obtém dados precisos e confiáveis de quanto trabalhou para cada empresa, sem conferir célula por célula ou refazer somas manualmente.

## Classificação do Projeto

**Tipo Técnico:** Web App
**Domínio:** General / Productivity (Time Tracking)
**Complexidade:** Low
**Contexto do Projeto:** Greenfield - novo projeto

**Justificativa da Classificação:**
- **Web App:** Sistema responsivo acessível via browser, sem necessidade de aplicativos nativos
- **Domínio Geral:** Ferramenta de produtividade sem requisitos regulatórios ou domínio especializado
- **Baixa Complexidade:** Funcionalidades CRUD padrão, cálculos simples, sem integrações complexas na fase inicial
- **Greenfield:** Projeto iniciado do zero sem codebase legado

## Critérios de Sucesso

### Sucesso do Usuário

O Cronos POC será considerado bem-sucedido do ponto de vista do usuário quando:

**Momento de Valor Principal:**
- O usuário consegue saber exatamente quanto trabalhou para cada empresa no mês **sem fazer contas manuais**
- Dados apresentados são aceitos pelas empresas contratantes sem questionamento

**Confiabilidade e Precisão:**
- 100% dos cálculos de tempo (duração entre início e fim) são executados automaticamente sem erros
- 100% dos cálculos de valores monetários (tempo × R$/hora por empresa) são precisos
- Zero risco de "bagunçar" o formato ou perder dados por erro de usuário

**Velocidade:**
- Registrar uma nova entrada de tempo leva aproximadamente 30 segundos (comparável ou mais rápido que planilha)
- Visualizar totais do mês é instantâneo (< 2 segundos)

**Visibilidade em Tempo Real:**
- Usuário consegue ver total de horas trabalhadas acumulado no mês até o momento
- Usuário consegue ver total do dia atual
- Usuário consegue ver total por empresa no mês
- Filtros permitem isolar visualizações por empresa, projeto, status ou data específica

### Sucesso do Negócio

**Fase MVP (3 meses):**
- Sistema está funcionalmente completo o suficiente para substituir a planilha Excel **completamente**
- Usuário principal (Igor) está usando o sistema como única fonte de registro de horas
- Dados do sistema são aceitos por todas as empresas contratantes para processamento de pagamento
- Zero necessidade de voltar para planilha ou conferir dados manualmente

**Visão Futura (12+ meses):**
- Sistema evolui para produto SaaS com múltiplos usuários
- Profissionais de diferentes áreas conseguem usar sem customização significativa
- Métricas de adoção e satisfação justificam investimento em crescimento

### Sucesso Técnico

**Confiabilidade:**
- Sistema mantém disponibilidade adequada para uso diário (web app responsivo sempre acessível)
- Dados persistidos de forma segura sem risco de perda
- Cálculos matemáticos implementados de forma robusta e testada

**Performance:**
- Listagem de entradas do mês carrega em < 2 segundos
- Filtros aplicam e atualizam visualização em < 1 segundo
- Interface responsiva funciona adequadamente em desktop e mobile

**Manutenibilidade:**
- Código organizado para facilitar adição de features futuras
- Arquitetura permite evolução para multi-tenant (preparação para SaaS)

### Resultados Mensuráveis

**Semana 1 de uso:**
- Usuário registra pelo menos 5 entradas de tempo com sucesso
- Tempo médio de registro por entrada ≤ 30 segundos
- Zero erros de cálculo detectados

**Mês 1 de uso:**
- 100% das entradas do mês registradas no sistema (abandono completo da planilha)
- Relatório mensal gerado e aceito por empresas contratantes
- Usuário reporta satisfação com confiabilidade e visibilidade dos dados

**Mês 3 (MVP completo):**
- Sistema em uso contínuo sem necessidade de fallback para planilha
- Todas as funcionalidades MVP funcionando conforme esperado
- Feedback do usuário orienta roadmap de features pós-MVP

## Escopo do Produto

### MVP - Minimum Viable Product

**Funcionalidades Obrigatórias:**

**1. Registro de Entradas de Tempo**
- Campos obrigatórios: Data, Início, Fim, Empresa, Projeto, Atividade, Status
- Status disponíveis: Pendente, Finalizado, Reaberto, Entregue
- Interface de entrada rápida e intuitiva

**2. Cálculos Automáticos**
- Tempo trabalhado calculado automaticamente (Fim - Início)
- Valor monetário calculado automaticamente (Tempo × R$/hora da empresa)
- R$/hora configurável por empresa

**3. Visualização de Entradas**
- Lista de entradas do mês atual
- Exibição clara de todas as informações: data, horários, tempo, empresa, projeto, atividade, status, valor

**4. Totais e Agregações**
- Total de horas do dia (soma de todas as entradas do mesmo dia)
- Total de horas por empresa no mês (soma filtrada por empresa)
- Total de valor por empresa no mês

**5. Filtros**
- Filtrar por empresa
- Filtrar por projeto
- Filtrar por status
- Filtrar por data/período

**6. Edição de Entradas (prioridade secundária)**
- Capacidade de editar entradas já registradas
- Capacidade de deletar entradas incorretas
- *Nota: Não é bloqueador para MVP, mas será implementado assim que possível*

**Fora do Escopo MVP:**
- Exportação para Excel/CSV (pós-MVP)
- Relatórios avançados ou gráficos
- Notificações ou lembretes
- Integração com Trello ou outras ferramentas
- Sistema de autenticação multi-usuário
- Timers automáticos (continua sendo registro manual)

### Funcionalidades de Crescimento (Pós-MVP)

**Prioridade Alta (primeiros 6 meses):**
- Exportação para Excel/CSV mantendo compatibilidade com formato atual
- Relatórios mensais formatados e prontos para envio
- Edição em massa de entradas
- Duplicação de entradas recorrentes

**Prioridade Média (6-12 meses):**
- Gráficos e visualizações de distribuição de tempo
- Comparativos mês-a-mês
- Alertas/notificações de horas não registradas
- Templates de atividades frequentes
- Suporte para múltiplos usuários (preparação SaaS)

**Prioridade Baixa (12+ meses):**
- Integração com Trello
- API para integrações externas
- Timers automáticos com play/pause
- Mobile apps nativos
- Análises preditivas de horas

### Visão de Longo Prazo (Futuro)

**Produto SaaS Completo:**
- Multi-tenant com isolamento de dados por usuário/empresa
- Planos de assinatura (freemium, pro, enterprise)
- Integrações com ferramentas populares (Jira, Asana, Slack)
- APIs públicas para ecossistema de integrações
- Funcionalidades colaborativas (aprovação de timesheet, gestão de equipe)
- Relatórios customizáveis e dashboards avançados
- Faturamento automatizado baseado em horas registradas

## Jornadas do Usuário

### Jornada 1: Igor - Registrando Horas do Dia sem Perder o Foco

Igor é desenvolvedor que trabalha simultaneamente para três empresas diferentes. Sua manhã começa com uma tarefa urgente do Trello para o projeto Tributário. Ele move o card "#14335 - Fix Agreement Cancellation" para a coluna "Fazendo" às 8h30 e mergulha no código.

Três horas depois, ele resolve o problema. Antes de mover o card para "Concluído", Igor sabe que precisa registrar essas horas. No fluxo antigo com planilha, ele abria o Excel, scrollava até a última linha, preenchia dia da semana, data, hora de início (8:30), deixava o fim em branco, selecionava "tributario" como projeto, marcava "Pendente" como status, e colava o ID da tarefa "#14335 - Fix Agreement Cancellation". Levava cerca de 1-2 minutos e quebrava sua concentração.

Com o Cronos POC, Igor abre o sistema web já logado (sempre aberto em outra aba). Clica em "Nova Entrada", um formulário limpo aparece já com a data de hoje preenchida. Ele digita rapidamente: início "08:30", fim "11:30", seleciona "Tributário" no dropdown de empresas (o sistema já conhece suas empresas), digita "tributario" como projeto, cola "#14335 - Fix Agreement Cancellation" na atividade, e confirma "Pendente". Clica em "Salvar" - tudo isso em 30 segundos.

O sistema calcula automaticamente: 3 horas trabalhadas × R$ 45/hora = R$ 135,00. Igor vê a entrada aparecer na lista do mês, com o total do dia atualizado para "3h". Ele respira aliviado - não precisa se preocupar se copiou a fórmula certa ou se vai lembrar dos detalhes mais tarde. Move o card no Trello para "Concluído" e já parte para a próxima tarefa, sabendo que seus dados estão seguros e corretos.

**Capacidades Reveladas por Esta Jornada:**
- Formulário de entrada rápido e intuitivo
- Auto-preenchimento da data atual
- Dropdown de empresas pré-cadastradas
- Cálculo automático de tempo e valor
- Feedback visual imediato (total do dia atualizado)
- Interface sempre acessível (web app responsivo)

### Jornada 2: Igor - Fechamento de Mês sem Planilhas

É dia 30 e Igor precisa enviar o timesheet para as três empresas que trabalhou no mês. No modelo antigo, ele abria a planilha Excel, conferia célula por célula se todas as fórmulas estavam corretas, somava manualmente os totais por empresa (porque nunca confia 100% na fórmula), e gerava um resumo para enviar. Isso levava facilmente 30-40 minutos e sempre vinha acompanhado de uma ansiedade: "Será que não tem erro? Será que vão questionar?"

Com o Cronos POC, Igor acessa o sistema e aplica o filtro "Empresa: Tributário". Instantaneamente vê todas as 45 entradas do mês para essa empresa, com o total já calculado: **127 horas = R$ 5.715,00**. Ele percorre a lista visualmente para garantir que tudo faz sentido - todas as tarefas estão lá, todos os status estão corretos. Confiante, ele anota esse valor.

Repete o processo para "Protocolo": **83 horas = R$ 4.150,00** (R$ 50/hora nessa empresa). E para "Cronos POC": **22 horas = R$ 990,00**. Total do mês: 232 horas trabalhadas, R$ 10.855,00 a receber. Todo o processo levou menos de 5 minutos.

Igor envia os valores para cada empresa sem aquela sensação de "torcer para estar certo". Ele sabe que cada cálculo foi feito automaticamente, sem risco de fórmula errada. Quando a empresa Tributário pede mais detalhes, ele simplesmente envia a lista filtrada mostrando dia por dia o que foi trabalhado. A empresa aceita sem questionar - os dados são claros, organizados e profissionais.

**Momento de Vitória:** Igor fecha o mês em minutos, não em horas. Pela primeira vez, ele não confere célula por célula. Ele simplesmente confia.

**Capacidades Reveladas por Esta Jornada:**
- Filtros por empresa funcionando instantaneamente
- Totalizadores automáticos confiáveis por empresa
- Visualização clara de todas as entradas filtradas
- Cálculos de valor respeitando R$/hora diferente por empresa
- Interface que gera confiança para envio direto às empresas

### Jornada 3: Igor - Corrigindo um Erro sem Medo

Na quarta-feira, Igor percebe que registrou uma tarefa do "Protocolo" com a empresa errada - marcou como "Tributário" por engano. São 4 horas que estão contabilizadas para a empresa errada, o que vai bagunçar o fechamento do mês.

No modelo da planilha, ele teria que encontrar a linha certa (scroll infinito), alterar a célula da empresa, e torcer para não ter quebrado nenhuma fórmula no processo. Sempre com aquele medo de "será que não estraguei outra coisa sem querer?".

Com o Cronos POC (pós-MVP com edição implementada), Igor abre o sistema, filtra por "Empresa: Tributário", encontra rapidamente a entrada errada (visualmente destaca da lista), clica em "Editar", altera o dropdown de "Tributário" para "Protocolo", e salva. O sistema recalcula automaticamente todos os totais - o total de Tributário diminui R$ 180, o total de Protocolo aumenta R$ 200 (porque essa empresa paga R$ 50/hora, não R$ 45). Correção feita em 20 segundos, sem risco, sem medo.

**Capacidades Reveladas por Esta Jornada:**
- Edição de entradas existentes (pós-MVP)
- Recalculo automático de totais após edição
- Busca/filtro facilitando encontrar entrada específica
- Validação que impede "quebrar" dados

### Jornada 4: Igor - Acompanhamento Semanal para Planejamento

É quinta-feira, dia 18, e Igor está planejando sua próxima semana. Ele quer saber: "Quanto já trabalhei para cada empresa este mês? Preciso equilibrar melhor?" e "Quantas horas fiz essa semana até agora?".

Na planilha, isso significava somar mentalmente ou criar fórmulas temporárias em células vazias. Trabalhoso e impreciso.

No Cronos POC, Igor abre o sistema e já vê na tela principal:
- **Total do mês até agora:** 127 horas
- **Tributário:** 68h (R$ 3.060)
- **Protocolo:** 41h (R$ 2.050)
- **Cronos POC:** 18h (R$ 810)

Ele aplica filtro de data "Últimos 7 dias" e vê que trabalhou 42 horas essa semana - um pouco acima do normal. Decide pegar mais leve na sexta. Toda essa análise levou 30 segundos. Ele tem visibilidade total sobre onde seu tempo está indo, em tempo real, sem esforço.

**Momento de Insight:** Igor percebe que está investindo muito mais tempo no Tributário do que imaginava. Decide conversar com essa empresa sobre aumentar o valor/hora ou reduzir o escopo.

**Capacidades Reveladas por Esta Jornada:**
- Dashboard/visão inicial mostrando totais acumulados
- Totais por empresa sempre visíveis
- Filtro por período de tempo (últimos 7 dias, semana atual, etc.)
- Dados em tempo real para tomada de decisão

### Resumo de Capacidades Necessárias

As jornadas acima revelam que o Cronos POC precisa entregar:

**Core (MVP):**
1. **Formulário de Registro Rápido:** Entrada em ~30s com auto-preenchimentos inteligentes
2. **Cálculos Automáticos Confiáveis:** Tempo e valor calculados sem erros
3. **Gestão de Empresas:** Cada empresa com seu próprio R$/hora configurável
4. **Visualização de Entradas:** Lista clara de todas as entradas do mês
5. **Totalizadores em Tempo Real:** Total do dia, total por empresa, total geral sempre atualizados
6. **Filtros Poderosos:** Por empresa, projeto, data, status - instantâneos
7. **Interface Sempre Disponível:** Web app responsivo acessível de qualquer lugar

**Pós-MVP (Crescimento):**
8. **Edição Segura:** Corrigir entradas sem medo de "quebrar" dados
9. **Filtros de Período Avançados:** Últimos 7 dias, semana atual, mês anterior
10. **Dashboard de Insights:** Visão geral que facilita planejamento e decisões

## Web App - Requisitos Específicos

### Visão Geral da Arquitetura Web

O Cronos POC é uma **aplicação web moderna** focada em usabilidade e performance para uso diário como ferramenta de produtividade pessoal. A arquitetura web prioriza simplicidade, responsividade e confiabilidade sobre complexidade desnecessária.

### Suporte a Navegadores

**Navegadores Suportados (MVP):**
- Chrome/Chromium (últimas 2 versões)
- Firefox (últimas 2 versões)
- Safari Desktop e iOS (últimas 2 versões)
- Edge (últimas 2 versões)

**Navegadores Mobile:**
- Safari iOS (iPhone/iPad) - CRÍTICO
- Chrome Android - CRÍTICO

**Fora do Escopo:**
- Internet Explorer (qualquer versão)
- Navegadores antigos (> 2 anos)

**Justificativa:** Como ferramenta pessoal de produtividade, o foco está em navegadores modernos que o usuário principal (desenvolvedor) já utiliza diariamente.

### Design Responsivo

**Abordagem:** Mobile-First

**Breakpoints Principais:**
- **Mobile:** < 768px (BASE - design inicial)
- **Tablet:** 768px - 1023px
- **Desktop:** ≥ 1024px (expansão do mobile)

**Justificativa Mobile-First:**
- Garante funcionalidade em todos os dispositivos desde o início
- Força simplificação da UI (beneficia todas as resoluções)
- Progressive enhancement para desktop

**Componentes Críticos Todos os Tamanhos:**
- Formulário de nova entrada (registro rápido)
- Visualização de lista de entradas
- Totais do dia/mês
- Filtros funcionais

### Performance e Carregamento

**Metas de Performance (alinhadas com Critérios de Sucesso):**
- **First Contentful Paint:** < 1.5s
- **Time to Interactive:** < 3s
- **Listagem de entradas do mês:** < 2s
- **Aplicação de filtros:** < 1s
- **Envio de formulário:** < 500ms (feedback visual imediato)

**Estratégias:**
- Lazy loading de dados não-críticos
- Paginação ou virtualização se necessário (> 200 entradas)
- Caching de empresas/projetos pré-cadastrados
- Otimização de queries no backend

### Atualização de Dados e Real-Time

**Abordagem de Atualização:**
- **Não usa WebSockets ou Server-Sent Events no MVP**
- Atualização via refresh manual ou polling simples
- Feedback visual imediato após ações (criar, editar, deletar)
- Totalizadores recalculados localmente após cada operação

**Justificativa:**
- Sistema single-user não requer sincronização em tempo real
- Complexidade de WebSockets não justificada para MVP
- Refresh manual é aceitável para uso pessoal

**Pós-MVP (se multi-user):**
- Considerar WebSockets para colaboração
- Notificações de mudanças de outras sessões

### SEO e Descoberta

**Requisitos de SEO:**
- **Nenhum** - ferramenta privada não precisa ser indexada
- Robots.txt bloqueando crawlers
- Sem necessidade de meta tags Open Graph ou Schema.org
- Sem sitemap

**Justificativa:**
Cronos POC é ferramenta de produtividade pessoal (potencialmente SaaS futuro), não conteúdo público. Login será obrigatório, sem páginas públicas para indexar.

### Acessibilidade

**Nível WCAG:** A (básico) - **PERMANENTE**

**Requisitos Mínimos:**
- HTML semântico correto (`<button>`, `<form>`, `<label>`, etc.)
- Contraste de cores adequado (mín. 4.5:1 para texto normal)
- Labels claros em todos os inputs
- Navegação por teclado funcional (Tab, Enter, Esc)
- Mensagens de erro descritivas

**Fora do Escopo (Permanente):**
- Certificação WCAG AA ou AAA
- Testes com usuários com deficiências
- Screen reader otimização avançada (ARIA attributes complexos)

**Justificativa:**
Ferramenta pessoal de produtividade para desenvolvedor. Acessibilidade básica garante código semântico e navegação por teclado, sem necessidade de compliance rigoroso.

### Considerações de Implementação

**Stack Tecnológico (a definir em Arquitetura):**
- Framework frontend moderno (React, Vue, ou similar)
- Backend API RESTful
- Banco de dados relacional (PostgreSQL, MySQL, ou similar)
- Autenticação simples (session-based ou JWT)

**Deployment:**
- Hospedagem web padrão (não requer infraestrutura especial)
- HTTPS obrigatório
- Backup automático de dados

**Segurança:**
- Autenticação obrigatória
- Proteção contra CSRF
- Validação de inputs client e server-side
- Sanitização de dados antes de renderizar
