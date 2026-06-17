---
storyId: '10.2'
epicId: 'DM-010'
status: 'ready_for_dev'
createdAt: '2026-06-17'
---

# Story 10.2: Padronizar Nomenclatura dos KPIs para "Tarefas do mês"

## Contexto

O sistema usa rótulos inconsistentes para o mesmo conceito em telas diferentes:

| Tela | Rótulo atual | Problema |
|------|-------------|----------|
| Dashboard | **Tasks Mês** | Termo em inglês |
| Resumo Diário | **Cards no mês** | Jargão técnico sem significado para o usuário |

Ambos devem exibir **"Tarefas do mês"** — português claro, consistente com o domínio.

Esta story deve ser implementada **após a Story 10.1**, pois a renomeação deve refletir
o valor já corrigido.

## User Story

**Como** Igor
**Quero** ver rótulos de KPI em português e consistentes entre as telas
**Para** entender imediatamente o que cada métrica representa, sem confusão

## Critérios de Aceite

- [ ] **AC1:** Dashboard: rótulo "Tasks Mês" alterado para "Tarefas do mês"
- [ ] **AC2:** Resumo Diário: rótulo "Cards no mês" alterado para "Tarefas do mês"
- [ ] **AC3:** Nenhum outro KPI visível usa termos em inglês ou jargão técnico
- [ ] **AC4:** Alteração cobre versão desktop e mobile (responsivo)
- [ ] **AC5:** Specs de nomenclatura atualizadas para refletir os novos rótulos

## Notas Técnicas

Arquivos a editar:

| Arquivo | Trecho a alterar |
|---------|-----------------|
| `app/views/dashboard/index.html.erb` | `Tasks Mês` → `Tarefas do mês` |
| `app/views/resumo_diario/index.html.erb` | `Cards no mês` → `Tarefas do mês` |

- Verificar se os rótulos estão em i18n (`pt-BR.yml`) — se sim, alterar lá
- Buscar por `Tasks Mês` e `Cards no mês` em toda a base para não deixar ocorrência esquecida
- Atualizar specs que verificam o texto do rótulo (accessibility_spec, request specs)

## Estimativa

**1 story point (~1h)**
- Edição das views/i18n: 30min
- Atualização de specs: 30min
