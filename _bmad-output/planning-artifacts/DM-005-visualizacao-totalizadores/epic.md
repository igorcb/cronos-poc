# Epic DM-005: Visualização & Totalizadores

**Domínio:** DM-005-visualizacao-totalizadores
**Tipo:** Consumo / Apresentação
**Status:** Em Progresso
**Prioridade:** Alta (onde o usuário extrai valor dos dados)

## Objetivo

Permitir que Igor visualize todas as suas entradas de tempo com totalizadores automáticos — total do dia, total por empresa no mês, valor monetário — de forma rápida, confiável e pronta para faturamento.

## Valor de Negócio

Registrar dados é necessário, mas o valor real está em **consumir** esses dados de forma clara:
- Total do dia em tempo real: "Já trabalhei 6h hoje"
- Total por empresa no mês: "Tributário: 127h = R$ 5.715,00"
- Dados prontos para faturamento sem manipulação manual
- Confiança para enviar direto às contratantes

**Momento de valor:** Igor abre o sistema e instantaneamente vê quanto trabalhou hoje, quanto acumulou no mês, e quanto vai receber de cada empresa. Sem abrir planilha, sem somar célula.

## Dependências

- **Predecessores:** DM-004 (Registro de Tempo — dados para visualizar)
- **Sucessores:** DM-006 (Filtros — refinam a visualização)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| N+1 Prevention | `includes(:company, :project, :task_items)` | Performance obrigatória, detectado por Bullet |
| Componentes | ViewComponent gem | Reutilizáveis, testáveis, encapsulados |
| Atualização | Turbo Streams | Totais atualizam sem reload após CRUD |
| Paginação | Condicional (> 200 entries) | Não sobrecarregar DOM desnecessariamente |
| Caching | Query caching padrão Rails | Simplicidade, sem Redis no MVP |

## Critérios de Aceite do Épico

- [ ] Listagem do mês carrega em < 2 segundos
- [ ] Zero N+1 queries (Bullet não dispara alertas)
- [ ] ViewComponent para Task Card renderiza corretamente
- [ ] Total de horas do dia atual exibido e atualizado em tempo real
- [ ] Total de horas por empresa no mês calculado corretamente
- [ ] Total de valor (R$) por empresa no mês calculado corretamente
- [ ] Turbo Streams atualizam totalizadores após criar/editar/deletar entry
- [ ] Paginação implementada se > 200 entradas

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-implementar-index-de-timeentries-com-eager-loading.md` | Implementar Index com Eager Loading |
| 002 | `002-criar-viewcomponent-para-timeentry-card.md` | Criar ViewComponent para Task Card |
| 003 | `003-implementar-totalizadores-dinamicos-total-do-dia.md` | Implementar Totalizadores - Total do Dia |
| 004 | `004-implementar-totalizadores-por-empresa-no-mes.md` | Implementar Totalizadores por Empresa/Mês |
| 005 | `005-configurar-turbo-streams-para-atualizacao-em-tempo-real.md` | Configurar Turbo Streams para Atualização Real-Time |

## Requisitos Rastreados

- FR7, FR8, FR9, FR10
- ARQ34-ARQ38, ARQ39
- NFR1, NFR2, NFR3, NFR6
