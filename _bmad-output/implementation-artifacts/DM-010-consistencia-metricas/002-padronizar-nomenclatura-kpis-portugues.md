# Story 10.2: Padronizar Nomenclatura dos KPIs para "Tarefas do mês"

**Status:** done
**Domínio:** DM-010-consistencia-metricas
**Data:** 2026-06-17
**Epic:** Epic 10 — Consistência de Métricas e Nomenclatura
**Story ID:** 10.2
**Story Key:** 10-2-padronizar-nomenclatura-kpis-portugues

---

## Contexto

O sistema usa rótulos inconsistentes para o mesmo conceito em telas diferentes:

| Tela | Rótulo atual | Problema |
|------|-------------|----------|
| Dashboard | **Tasks Mês** | Termo em inglês |
| Resumo Diário | **Cards no mês** | Jargão técnico sem significado para o usuário |

Ambos devem exibir **"Tarefas do mês"** — português claro, consistente com o domínio.

Esta story deve ser implementada **após a Story 10.1**, pois a renomeação deve refletir
o valor já corrigido.

---

## História do Usuário

**Como** Igor,
**Quero** ver rótulos de KPI em português e consistentes entre as telas,
**Para** entender imediatamente o que cada métrica representa, sem confusão.

---

## Critérios de Aceite

- [x] **AC1:** Dashboard: rótulo "Tasks Mês" alterado para "Tarefas do mês"
- [x] **AC2:** Resumo Diário: rótulo "Cards no mês" alterado para "Tarefas do mês"
- [x] **AC3:** Nenhum outro KPI visível usa termos em inglês ou jargão técnico ("Tasks Hoje" → "Tarefas hoje")
- [x] **AC4:** Alteração cobre versão desktop e mobile (responsivo — só troca de texto, sem alteração de classes Tailwind)
- [x] **AC5:** Specs de nomenclatura atualizadas para refletir os novos rótulos

---

## Análise Técnica

### Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/dashboard/index.html.erb` | `Tasks Mês` → `Tarefas do mês` |
| `app/views/resumo_diario/index.html.erb` | `Cards no mês` → `Tarefas do mês` |
| `config/locales/pt-BR.yml` | Atualizar chave se rótulos vierem de i18n |
| Specs afetados | Atualizar strings dos rótulos nas asserções |

### Busca preventiva

Antes de editar, buscar todas as ocorrências para não deixar nada para trás:

```bash
grep -r "Tasks Mês\|Cards no mês" app/ spec/ config/
```

---

## Testes

- [ ] View do Dashboard renderiza "Tarefas do mês" (não "Tasks Mês")
- [ ] View do Resumo Diário renderiza "Tarefas do mês" (não "Cards no mês")
- [ ] Nenhuma ocorrência de "Tasks Mês" ou "Cards no mês" restante na base
- [ ] Specs de acessibilidade e mobile não quebram com o novo rótulo

---

## Dependências

- Story **10.1** concluída — o rótulo deve refletir o valor já corrigido

---

## Estimativa

**1 story point** (~1h) — edição de views/i18n (30min) + atualização de specs (30min)
