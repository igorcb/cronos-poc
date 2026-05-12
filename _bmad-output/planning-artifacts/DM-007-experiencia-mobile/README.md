# DM-007: Experiência Mobile & Responsividade

**Domínio:** Transversal / Experiência
**Epic Relacionado:** Epic 8
**Status:** Pendente

## Descrição

Domínio responsável pela experiência mobile-first, responsividade em múltiplos dispositivos e acessibilidade básica (WCAG Nível A). Garante que o sistema funcione adequadamente em desktop, tablet e mobile.

## Capacidades

| Capacidade | Descrição |
|------------|-----------|
| Mobile-First | Design base para mobile, expandido para desktop |
| Breakpoints | Mobile (< 768px), Tablet (768-1023px), Desktop (>= 1024px) |
| Form Mobile | Formulários otimizados para touch (inputs maiores, spacing adequado) |
| Acessibilidade | WCAG Nível A: HTML semântico, contraste, navegação por teclado |
| Cross-Browser | Chrome, Firefox, Safari (desktop/mobile), Edge |

## Regras de Negócio

1. **Mobile-First:** CSS base é para mobile, breakpoints expandem para tablet/desktop
2. **Componentes Críticos em Todos os Tamanhos:** Formulário de nova entrada, lista de entradas, totais, filtros
3. **Touch-Friendly:** Targets de toque mínimo 44x44px em mobile
4. **Formulários Mobile:** Inputs type correto (date, time, number) para teclados nativos
5. **Acessibilidade Permanente (WCAG-A):**
   - HTML semântico (`<button>`, `<form>`, `<label>`)
   - Contraste mínimo 4.5:1
   - Labels em todos os inputs
   - Navegação por teclado (Tab, Enter, Esc)
   - Mensagens de erro descritivas
6. **Fora do Escopo Permanente:** WCAG AA/AAA, testes com screen readers avançados

## Breakpoints Tailwind

```css
/* Mobile: default (< 768px) */
/* Tablet: md: (>= 768px) */
/* Desktop: lg: (>= 1024px) */
```

## Requisitos Cobertos

### Não-Funcionais
- NFR7: Abordagem Mobile-First
- NFR8: Funcional em Mobile, Tablet e Desktop
- NFR9: Compatibilidade cross-browser (últimas 2 versões)
- NFR18: WCAG Nível A
- NFR19: HTML semântico
- NFR20: Navegação por teclado
- NFR21: Contraste mínimo 4.5:1

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 8.1 | Implementar Mobile-First com Tailwind Breakpoints | Pendente |
| 8.2 | Otimizar TimeEntry Form para Mobile | Pendente |
| 8.3 | Garantir Acessibilidade WCAG Nível A | Pendente |
| 8.4 | Testar Responsividade em Múltiplos Dispositivos | Pendente |
