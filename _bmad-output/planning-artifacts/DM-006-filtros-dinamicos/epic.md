# Epic DM-006: Filtros Dinâmicos

**Domínio:** DM-006-filtros-dinamicos
**Tipo:** Consumo / Interação
**Status:** Pendente
**Prioridade:** Alta (essencial para fechamento mensal)

## Objetivo

Permitir que Igor filtre entradas por empresa, projeto, status e data/período de forma instantânea, com recálculo automático de totalizadores, para que o fechamento mensal seja feito em minutos — não em horas.

## Valor de Negócio

O fechamento mensal é o **momento de maior valor** do sistema. Sem filtros:
- Igor teria que percorrer todas as entradas manualmente
- Não conseguiria isolar dados por empresa para faturamento
- Perderia a vantagem sobre a planilha

Com filtros funcionando:
- "Empresa: Tributário" → 127h = R$ 5.715,00 (instantâneo)
- "Últimos 7 dias" → 42h trabalhadas essa semana
- Todo o fechamento de 3 empresas em < 5 minutos

**Momento de valor (Jornada 2 do PRD):** Igor fecha o mês em minutos, não em horas. Pela primeira vez, ele não confere célula por célula.

## Dependências

- **Predecessores:** DM-005 (Visualização — base de listagem e totalizadores)
- **Sucessores:** Nenhum direto (feature completa em si)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Client-side | Stimulus controllers | Estado dos filtros gerenciado no browser |
| Server-side | Turbo Frames | Resultados atualizados sem reload completo |
| Combináveis | Query params compostos | Empresa + Status + Período simultaneamente |
| Períodos | Presets + customizado | "Mês atual", "Últimos 7 dias", range manual |
| Performance | Índices compostos no DB | `[company_id, date]`, `[status]` já existentes |

## Critérios de Aceite do Épico

- [ ] Filtro por empresa funciona e isola entradas corretamente
- [ ] Filtro por projeto funciona e isola entradas corretamente
- [ ] Filtro por status (pending, completed, delivered) funciona
- [ ] Filtro por data/período funciona (presets + range customizado)
- [ ] Filtros são combináveis (empresa + status + período)
- [ ] Totalizadores (horas e R$) recalculam após cada filtro (< 1s)
- [ ] Stimulus controller gerencia estado dos filtros sem reload
- [ ] Turbo Frames atualizam resultados parcialmente
- [ ] Filtros persistem durante navegação na página

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-implementar-filtros-por-empresa-e-projeto.md` | Implementar Filtros por Empresa e Projeto |
| 002 | `002-implementar-filtros-por-status-e-data-periodo.md` | Implementar Filtros por Status e Data/Período |
| 003 | `003-recalcular-totalizadores-conforme-filtros-aplicados.md` | Recalcular Totalizadores com Filtros |
| 004 | `004-criar-stimulus-controller-para-filtros-com-turbo-frames.md` | Criar Stimulus Controller para Filtros |

## Requisitos Rastreados

- FR11, FR12, FR13, FR14, FR15
- ARQ45-ARQ46
- NFR4
