# Story 5.15: Corrigir Fuso Horário — Configurar Timezone Brasilia

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-30
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.15
**Story Key:** 5-15-corrigir-fuso-horario-brasilia

---

## Contexto

O `config.time_zone` estava comentado no `application.rb`, fazendo o Rails usar UTC por padrão. Como o servidor opera no fuso horário UTC-3 (Brasília), `Date.current` retornava a data errada, causando KPIs de "hoje" zerados mesmo com dados existentes — especialmente visível após meia-noite horário local.

---

## História do Usuário

**Como** usuário do Cronos POC no Brasil,
**Quero** que os KPIs de "Horas Hoje", "Tasks Hoje" e "Valor Hoje" reflitam o dia correto no horário de Brasília,
**Para** não ver dados zerados quando na verdade há lançamentos do dia.

---

## Critérios de Aceite

- [x] **AC1 — Timezone configurado:** `config.time_zone = "Brasilia"` ativo em `config/application.rb`
- [x] **AC2 — Date.current correto:** `Date.current` retorna a data no fuso UTC-3
- [x] **AC3 — KPIs diários corretos:** "Horas Hoje", "Tasks Hoje" e "Valor Hoje" calculam com a data local do Brasil

---

## Análise Técnica

### Modificação

```ruby
# config/application.rb — linha 36
config.time_zone = "Brasilia"
```

`Date.current` no Rails respeita `Time.zone`, que é definido pelo `config.time_zone`. Com UTC, a virada de dia acontecia às 21h no horário de Brasília. Com `"Brasilia"`, a virada ocorre à meia-noite local.

---

## Arquivos Modificados

| Arquivo | Ação |
|---------|------|
| `config/application.rb` | Descomentar e definir `config.time_zone = "Brasilia"` |

---

## Estimativa

**0.5 story point** (~30min) — alteração de 1 linha, impacto sistêmico.

---

## Dev Agent Record

### Completion Notes

- ✅ AC1: `config.time_zone = "Brasilia"` ativo
- ✅ AC2: Verificado via `rails runner "puts Time.zone.name"` → `Brasilia`
- ✅ AC3: `Date.current` retorna `2026-04-30` no UTC-3

### Change Log

- 2026-04-30: Timezone configurado para Brasilia — KPIs diários agora calculam com data local brasileira
