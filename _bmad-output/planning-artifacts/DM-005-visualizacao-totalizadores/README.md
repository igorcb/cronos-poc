# DM-005: Visualização & Totalizadores

**Domínio:** Consumo / Apresentação
**Epic Relacionado:** Epic 5
**Status:** Em Progresso

## Descrição

Domínio responsável pela visualização de entradas de tempo e cálculo de totalizadores automáticos. É onde o usuário extrai valor dos dados registrados — totais por dia, mês e empresa, prontos para faturamento.

## Capacidades

| Capacidade | Descrição |
|------------|-----------|
| Listagem de Entradas | Lista de todas as entradas do mês com eager loading |
| Task Card Component | ViewComponent para exibição individual de tarefas |
| Total do Dia | Soma de horas trabalhadas no dia atual |
| Total por Empresa/Mês | Horas e valores agrupados por empresa no mês |
| Turbo Streams | Atualização em tempo real dos totalizadores |

## Regras de Negócio

1. **Eager Loading Obrigatório:** Listagem deve usar `includes(:company, :project, :task_items)` para prevenir N+1 queries
2. **Total do Dia:** Soma de `hours_worked` de todos os TaskItems do dia atual
3. **Total por Empresa:** Agrupamento por `company_id` com soma de horas e cálculo de valor (`hours * hourly_rate`)
4. **Performance:** Listagem do mês deve carregar em < 2 segundos
5. **Paginação:** Implementar se houver > 200 entradas
6. **ViewComponent:** Componentes reutilizáveis para cards de tarefas (gem ViewComponent)
7. **Turbo Streams:** Totalizadores atualizam via Turbo após criação/edição/deleção

## Requisitos Cobertos

### Funcionais
- FR7: Lista de entradas do mês com todas as informações
- FR8: Total de horas do dia atual
- FR9: Total de horas por empresa no mês
- FR10: Total de valor monetário por empresa no mês

### Arquiteturais
- ARQ34-ARQ38: Query caching, eager loading, índices
- ARQ39: ViewComponent para componentes UI

### Não-Funcionais
- NFR1: First Contentful Paint < 1.5s
- NFR2: Time to Interactive < 3s
- NFR3: Listagem do mês < 2s
- NFR6: Paginação se > 200 entradas

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 5.1 | Implementar Index de TimeEntries com Eager Loading | Em Progresso |
| 5.2 | Criar ViewComponent para TimeEntry Card | Pendente |
| 5.3 | Implementar Totalizadores Dinâmicos - Total do Dia | Pendente |
| 5.4 | Implementar Totalizadores por Empresa no Mês | Pendente |
| 5.5 | Configurar Turbo Streams para Atualização em Tempo Real | Pendente |
