# Epic DM-007: Experiência Mobile & Responsividade

**Domínio:** DM-007-experiencia-mobile
**Tipo:** Transversal / Experiência
**Status:** Pendente
**Prioridade:** Média (melhoria de experiência, não bloqueador funcional)

## Objetivo

Garantir que o Cronos POC funcione de forma excelente em qualquer dispositivo — mobile, tablet, desktop — com abordagem mobile-first, formulários otimizados para touch, e acessibilidade básica (WCAG-A).

## Valor de Negócio

Igor registra horas ao longo do dia, muitas vezes pelo celular entre reuniões. Se a experiência mobile for ruim:
- Ele adiará o registro e esquecerá detalhes
- Voltará para a planilha "porque é mais rápido no celular"
- O sistema perde sua utilidade como ferramenta de uso diário

Com mobile otimizado:
- Registro de tempo pelo celular em 30 segundos
- Teclados nativos para date/time/number
- Interface touch-friendly sem frustração

**Momento de valor:** Igor está no ônibus, abre o Cronos no celular, registra as 3h que trabalhou de manhã antes de esquecer. Tudo em 30s, sem zoom ou scroll horizontal.

## Dependências

- **Predecessores:** DM-004, DM-005, DM-006 (funcionalidades que serão adaptadas)
- **Sucessores:** Nenhum (épico de polimento)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Abordagem | Mobile-First | Base em mobile, progressive enhancement para desktop |
| Framework CSS | Tailwind (utility-first) | Breakpoints nativos: `md:`, `lg:` |
| Breakpoints | <768px, 768-1023px, >=1024px | Standard Tailwind: mobile, md, lg |
| Touch | Min 44x44px targets | Apple HIG / Material Design guidelines |
| Inputs | HTML5 types nativos | `type="date"`, `type="time"`, `type="number"` |
| Acessibilidade | WCAG-A permanente | Básico mas consistente, sem compliance rigoroso |

## Critérios de Aceite do Épico

- [ ] Layout mobile-first: todas as telas funcionam em < 768px
- [ ] Breakpoints Tailwind aplicados: mobile → md (tablet) → lg (desktop)
- [ ] Formulário de nova task otimizado para touch (inputs 44x44px mín.)
- [ ] Inputs usam types HTML5 corretos (date, time, number)
- [ ] HTML semântico em todas as páginas (`<button>`, `<form>`, `<label>`)
- [ ] Contraste mínimo 4.5:1 em todos os textos
- [ ] Labels associados a todos os inputs
- [ ] Navegação por teclado funcional (Tab, Enter, Esc)
- [ ] Mensagens de erro descritivas e acessíveis
- [ ] Testado em Chrome mobile, Safari iOS, Chrome Android

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-implementar-mobile-first-com-tailwind-breakpoints.md` | Implementar Mobile-First com Tailwind Breakpoints |
| 002 | `002-otimizar-timeentry-form-para-mobile.md` | Otimizar Form para Mobile |
| 003 | `003-garantir-acessibilidade-wcag-nivel-a.md` | Garantir Acessibilidade WCAG Nível A |
| 004 | `004-testar-responsividade-em-multiplos-dispositivos.md` | Testar Responsividade Multi-Dispositivo |

## Requisitos Rastreados

- NFR7, NFR8, NFR9
- NFR18, NFR19, NFR20, NFR21
