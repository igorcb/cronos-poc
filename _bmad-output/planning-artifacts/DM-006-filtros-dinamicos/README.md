# DM-006: Filtros Dinâmicos

**Domínio:** Consumo / Interação
**Epic Relacionado:** Epic 6
**Status:** Pendente

## Descrição

Domínio responsável pelos filtros interativos que permitem ao usuário isolar visualizações por empresa, projeto, status e data/período. Essencial para o fechamento mensal — o momento onde o usuário extrai dados por empresa para faturamento.

## Capacidades

| Capacidade | Descrição |
|------------|-----------|
| Filtro por Empresa | Isolar entradas de uma empresa específica |
| Filtro por Projeto | Isolar entradas de um projeto específico |
| Filtro por Status | Filtrar por pending, completed, delivered |
| Filtro por Data/Período | Filtrar por data específica ou range de datas |
| Recálculo de Totalizadores | Totais são recalculados após aplicação de filtros |

## Regras de Negócio

1. **Filtros Combináveis:** Usuário pode combinar múltiplos filtros simultaneamente (empresa + status + período)
2. **Recálculo Instantâneo:** Totalizadores (horas, valores) devem recalcular após cada filtro aplicado (< 1s)
3. **Filtros via Stimulus:** Controllers JavaScript gerenciam estado dos filtros client-side
4. **Turbo Frames:** Resultados filtrados são atualizados via Turbo Frames sem reload completo
5. **Persistência de Filtros:** Filtros ativos devem ser mantidos durante a navegação na página
6. **Filtro de Período:** Suporte a "Últimos 7 dias", "Semana atual", "Mês atual", "Mês anterior", range customizado

## Jornada Principal

**Fechamento de Mês (Jornada 2 do PRD):**
- Igor filtra por "Empresa: Tributário" → vê 45 entradas, total 127h = R$ 5.715,00
- Repete para cada empresa
- Todo o fechamento em < 5 minutos

## Requisitos Cobertos

### Funcionais
- FR11: Filtro por empresa (company_id)
- FR12: Filtro por projeto (project_id)
- FR13: Filtro por status
- FR14: Filtro por data/período
- FR15: Recálculo de totalizadores após filtros

### Arquiteturais
- ARQ45-ARQ46: Naming de Turbo Frames e Stimulus controllers

### Não-Funcionais
- NFR4: Aplicação de filtros < 1s

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 6.1 | Implementar Filtros por Empresa e Projeto | Pendente |
| 6.2 | Implementar Filtros por Status e Data/Período | Pendente |
| 6.3 | Recalcular Totalizadores Conforme Filtros Aplicados | Pendente |
| 6.4 | Criar Stimulus Controller para Filtros com Turbo Frames | Pendente |
