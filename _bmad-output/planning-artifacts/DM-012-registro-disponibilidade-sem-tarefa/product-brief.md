# Product Brief — DM-012: Registro de Disponibilidade sem Tarefa

## Contexto

Igor trabalha sob contrato com carga horária mínima de 190h/mês e máxima de 300h/mês, com disponibilidade diária de até 11h em dias úteis e 6h em finais de semana. Nem sempre há tarefas disponíveis para execução durante esse período de disponibilidade.

Hoje o Cronos contabiliza apenas horas efetivamente lançadas em Tasks. Quando o total mensal fica abaixo de 190h, não há como distinguir, a partir do sistema, se o motivo foi indisponibilidade do profissional ou ausência de demanda (falta de tarefas atribuídas). Isso expõe o usuário a questionamentos indevidos sobre cumprimento de carga horária.

## Problema

Não existe hoje, no Cronos, um jeito de registrar e evidenciar períodos em que o usuário esteve disponível para trabalhar mas não havia tarefa para executar. Sem esse registro, o profissional não tem como comprovar formalmente que o não cumprimento das 190h mensais não foi por sua indisponibilidade.

## Objetivo

Permitir que o usuário registre manualmente períodos de "Sem Tarefa" (início/fim), e visualizar via KPI o total de horas nessa condição por dia/mês — funcionando como evidência de disponibilidade ociosa por falta de demanda, sem impactar o total de horas trabalhadas.

## Usuários

- Usuário do Cronos sujeito a contrato de carga horária mínima/máxima mensal, que precisa justificar gaps de horas não trabalhadas por ausência de tarefas.

## Escopo

**Nesta entrega (Web apenas — não mexer em mobile):**
- Novo tipo de registro "Sem Tarefa", separado de Task, com campos de início e fim (marcação manual, não retroativa/calculada)
- Esse registro **não soma** no total de horas trabalhadas (não conta para 190h/300h)
- Novo KPI no dashboard mostrando total de horas "Sem Tarefa" no período filtrado (dia/mês), seguindo o padrão de KPIs existente (DM-005, DM-010)

**Fora de escopo (por ora):**
- Qualquer alteração no app mobile (architecture-mobile.md / prd-mobile.md / epics-mobile.md permanecem intocados)
- Cálculo automático de gaps a partir do calendário de disponibilidade
- Uso desse registro para contagem de horas cumpridas do contrato
- Campo de motivo/observação (não solicitado — validar com PM se necessário)

## Métrica de sucesso

- Usuário consegue, ao final do mês, visualizar quantas horas ficou "Sem Tarefa" e usar esse número como evidência objetiva junto à empresa.

## Riscos e considerações técnicas (para arquitetura)

- Definir se "Sem Tarefa" é um novo model (`IdlePeriod`?) ou uma extensão do model `Task`/`TaskItem` existente com um tipo/flag — decisão de arquitetura, não deste brief.
- Precisa se integrar ao padrão de Turbo Stream de totalizadores já usado nos KPIs existentes (ver padrões em DM-005 e DM-010).
- Validar overlap entre período "Sem Tarefa" e Tasks já lançadas (regra de negócio a definir com PM/Arquitetura).

## Próximos passos

1. PM (John): transformar este brief em PRD incremental do Cronos web (ou seção nova no `prd.md` existente)
2. Arquiteto (Winston): decidir modelagem de dados e integração com KPIs/Turbo Stream
3. SM (Bob): quebrar em épicos/stories e incluir no sprint plan
