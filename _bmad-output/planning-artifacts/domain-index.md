# Cronos POC - Índice de Domínios

## Visão Geral

O Cronos POC é organizado em 7 domínios que cobrem desde a infraestrutura técnica até a experiência do usuário final.

## Mapa de Domínios

| Código | Domínio | Tipo | Epics | Status |
|--------|---------|------|-------|--------|
| DM-001 | [Autenticação & Infraestrutura](DM-001-autenticacao-infraestrutura/README.md) | Transversal | Epic 1 | Concluído |
| DM-002 | [Gestão de Empresas](DM-002-empresas/README.md) | Suporte | Epic 2 | Concluído |
| DM-003 | [Gestão de Projetos](DM-003-projetos/README.md) | Suporte | Epic 3 | Concluído |
| DM-004 | [Registro de Tempo](DM-004-registro-tempo/README.md) | **Core** | Epic 4, 7 | Em Progresso |
| DM-005 | [Visualização & Totalizadores](DM-005-visualizacao-totalizadores/README.md) | Consumo | Epic 5 | Em Progresso |
| DM-006 | [Filtros Dinâmicos](DM-006-filtros-dinamicos/README.md) | Consumo | Epic 6 | Pendente |
| DM-007 | [Experiência Mobile](DM-007-experiencia-mobile/README.md) | Transversal | Epic 8 | Pendente |

## Fluxo de Dependências

```
DM-001 (Infraestrutura)
  └── DM-002 (Empresas)
        └── DM-003 (Projetos)
              └── DM-004 (Registro de Tempo) ← CORE
                    ├── DM-005 (Visualização)
                    │     └── DM-006 (Filtros)
                    └── DM-007 (Mobile) ← Transversal
```

## Estatísticas

- **Total de Stories:** 34
- **Stories Concluídas:** ~22 (Epics 1-4)
- **Stories em Progresso:** ~5 (Epic 5)
- **Stories Pendentes:** ~7 (Epics 6-8)
