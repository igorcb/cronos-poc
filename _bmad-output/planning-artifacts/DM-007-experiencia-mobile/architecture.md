# Arquitetura - DM-007: Experiência Mobile & Responsividade

**Domínio:** DM-007-experiencia-mobile
**Tipo:** Transversal / Experiência
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Este domínio não introduz novos models ou controllers — ele define padrões de CSS, HTML e acessibilidade que se aplicam transversalmente a todos os outros domínios. A abordagem é mobile-first com progressive enhancement.

## Estratégia Mobile-First

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Mobile    │────▶│   Tablet    │────▶│   Desktop   │
│  < 768px    │     │  768-1023px │     │  >= 1024px  │
│  (DEFAULT)  │     │    (md:)    │     │    (lg:)    │
└─────────────┘     └─────────────┘     └─────────────┘
    Base CSS          Expansão 1          Expansão 2
```

**Princípio:** CSS base é mobile. Breakpoints `md:` e `lg:` do Tailwind adicionam regras para telas maiores.

## Decisões Arquiteturais

### DA-060: Tailwind Breakpoints

**Escolha:** Breakpoints padrão do Tailwind (não customizados)

```css
/* Mobile: estilos base (sem prefixo) */
.card { @apply p-3 space-y-2; }

/* Tablet: md: (>= 768px) */
.card { @apply md:p-4 md:flex md:space-x-4; }

/* Desktop: lg: (>= 1024px) */
.card { @apply lg:p-6 lg:grid lg:grid-cols-3; }
```

**Justificativa:** Breakpoints padrão são bem documentados, testados, e cobrem os dispositivos mais comuns. Customizar adicionaria complexidade sem benefício.

### DA-061: Formulários Touch-Friendly

**Escolha:** Inputs HTML5 nativos com sizing adequado

| Input | HTML Type | Justificativa |
|-------|-----------|---------------|
| Data | `type="date"` | Date picker nativo do OS |
| Hora | `type="time"` | Time picker nativo do OS |
| Valor | `type="number" step="0.01"` | Teclado numérico em mobile |
| Texto | `type="text"` | Teclado padrão |
| Select | `<select>` | Dropdown nativo do OS |

**Sizing:**
```html
<!-- Mínimo 44x44px para touch targets -->
<input class="h-11 px-3 text-base w-full rounded-lg border" />
<button class="h-11 px-6 text-base font-medium rounded-lg" />
<select class="h-11 px-3 text-base w-full rounded-lg border" />
```

**Justificativa:** Inputs nativos HTML5 ativam teclados específicos do OS (date picker, time picker, teclado numérico). Componentes custom JS seriam piores em mobile.

### DA-062: Layout Responsivo por Componente

| Componente | Mobile (< 768px) | Tablet (md:) | Desktop (lg:) |
|------------|-------------------|--------------|----------------|
| Task Card | Stack vertical, full-width | 2 colunas | 3 colunas grid |
| Form | Stack vertical | 2 colunas | 3 colunas |
| Filtros | Collapsible accordion | Inline horizontal | Inline horizontal |
| Totalizadores | Stack vertical, cards | Grid 2 colunas | Grid 3-4 colunas |
| Navegação | Hamburger menu | Sidebar compact | Sidebar expandida |

### DA-063: Acessibilidade WCAG Nível A

**Escolha:** WCAG-A como padrão permanente (não AA ou AAA)

| Requisito WCAG-A | Implementação |
|-------------------|---------------|
| HTML Semântico | `<button>`, `<form>`, `<label>`, `<nav>`, `<main>`, `<header>` |
| Contraste 4.5:1 | Tailwind colors verificadas (gray-700+ para texto em branco) |
| Labels | `<label for="...">` em todo `<input>` |
| Navegação por teclado | Tab order natural, `:focus-visible` rings |
| Alt text | `alt=""` em imagens decorativas, texto descritivo em funcionais |
| Error messages | `role="alert"` + `aria-describedby` |
| Skip links | Link "Ir para conteúdo" no topo |

**Fora do escopo permanente:**
- WCAG AA/AAA
- Screen reader optimization avançada
- Testes com usuários com deficiência

**Justificativa:** Para ferramenta pessoal de produtividade, WCAG-A garante código semântico e navegação por teclado (beneficia todos os usuários) sem overhead de compliance.

### DA-064: Compatibilidade Cross-Browser

| Browser | Versões | Prioridade |
|---------|---------|-----------|
| Chrome/Chromium | Últimas 2 | Alta |
| Firefox | Últimas 2 | Alta |
| Safari iOS | Últimas 2 | **Crítica** (uso mobile) |
| Chrome Android | Últimas 2 | **Crítica** (uso mobile) |
| Safari Desktop | Últimas 2 | Média |
| Edge | Últimas 2 | Baixa |

**Fora do escopo:** IE (qualquer versão), browsers > 2 anos.

**Estratégia:** Uso de CSS features amplamente suportadas. Tailwind já cuida de prefixos vendor automaticamente.

## Padrões CSS

### Spacing System (Tailwind)

```
Mobile:  p-3, gap-2, space-y-2 (compacto)
Tablet:  md:p-4, md:gap-4, md:space-y-3
Desktop: lg:p-6, lg:gap-6, lg:space-y-4
```

### Typography Scale

```
Títulos:  text-lg / md:text-xl / lg:text-2xl
Corpo:    text-base (16px — legível em todos os devices)
Labels:   text-sm / text-gray-600
Valores:  text-lg font-bold (destaque monetário)
```

### Color Palette (Status)

```
Pending:   bg-yellow-100 text-yellow-800 (contraste 5.4:1 ✅)
Completed: bg-green-100 text-green-800   (contraste 5.1:1 ✅)
Delivered: bg-blue-100 text-blue-800      (contraste 5.2:1 ✅)
Error:     bg-red-100 text-red-800        (contraste 5.6:1 ✅)
```

## Testes de Responsividade

| Dispositivo | Viewport | Método |
|-------------|----------|--------|
| iPhone SE | 375×667 | Chrome DevTools |
| iPhone 14 | 390×844 | Chrome DevTools |
| iPad | 768×1024 | Chrome DevTools |
| Desktop | 1440×900 | Browser nativo |

**Testes automatizados:** System specs com Capybara podem definir viewport size via `page.driver.browser.manage.window.resize_to(375, 667)`.

## Interface com Outros Domínios

Este domínio é **transversal** — não consome dados de outros domínios, mas define padrões visuais que todos devem seguir:

| Domínio | Impacto da Responsividade |
|---------|---------------------------|
| DM-002 (Empresas) | Form e listagem responsivos |
| DM-003 (Projetos) | Form e listagem responsivos |
| DM-004 (Registro) | Form de task otimizado para mobile (prioridade máxima) |
| DM-005 (Visualização) | Cards e totalizadores adaptativos |
| DM-006 (Filtros) | Filtros collapsible em mobile |
