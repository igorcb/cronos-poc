# Story 11.4: Acessibilidade WCAG Nível AA Completa

**Status:** ready-for-dev
**Domínio:** DM-010-observabilidade-ux-polish
**Epic:** Epic 11 — Observabilidade & UX Polish
**Story ID:** 11.4
**Prioridade:** MEDIUM
**Estimativa:** 2 SP

---

## Contexto

O projeto já tem WCAG nível A entregue (Story 8.3). Para nível **AA** (padrão profissional / requisito legal em vários países), faltam:

1. **Contraste de cores** — verificar todos os pares foreground/background batem ratio 4.5:1 (texto normal) e 3:1 (texto grande)
2. **Focus visible** — todos elementos interativos têm outline claro no `:focus-visible`
3. **Resize 200%** — texto continua legível ao ampliar 200% sem perder funcionalidade
4. **Reflow** — sem scroll horizontal em viewport de 320px (já parcialmente atendido pelo mobile-first)
5. **Identificação consistente** — botões com mesma função têm label igual em todo o app
6. **Erros de validação** — descrição clara + sugestão de correção em cada campo inválido

---

## História do Usuário

**Como** usuário com baixa visão ou que usa leitor de tela,
**Quero** que o Cronos POC atenda WCAG nível AA,
**Para** poder usar todas as funcionalidades sem barreiras.

---

## Critérios de Aceite

### AC1 — Auditoria inicial
- [ ] **AC1.1:** Rodar axe DevTools nas 5 telas principais (login, dashboard, /tasks, /tasks/new, /resumo-diario)
- [ ] **AC1.2:** Documentar findings em `_bmad-output/implementation-artifacts/DM-010-observabilidade-ux-polish/wcag-aa-audit-findings.md`
- [ ] **AC1.3:** Categorizar por tipo (contraste, focus, labels, etc.)

### AC2 — Contraste de cores (1.4.3 / 1.4.11)
- [ ] **AC2.1:** Verificar contraste de texto cinza (`text-gray-400`) sobre `bg-gray-800` → ratio mínimo 4.5:1 para texto normal
- [ ] **AC2.2:** Verificar texto em estado disabled (opacidade < 100%) — pode ser ratio menor, mas validar legibilidade
- [ ] **AC2.3:** Badges de status (Delivered/Completed/Pending) — texto sobre cor de fundo → ratio 4.5:1
- [ ] **AC2.4:** Botões primary/secondary/danger — text + bg ratio 4.5:1
- [ ] **AC2.5:** Ajustar paleta Tailwind onde falhar

### AC3 — Focus visible (2.4.7)
- [ ] **AC3.1:** Adicionar `focus:outline-none focus:ring-2 focus:ring-blue-500` consistente em todos os botões/links
- [ ] **AC3.2:** Testar navegação via Tab — outline azul visível em cada elemento
- [ ] **AC3.3:** Tabs do form edit (`tab-dados`, `tab-horas`, `tab-financeiro`) já têm focus ring (verificar)

### AC4 — Resize 200% (1.4.4)
- [ ] **AC4.1:** Browser DevTools → zoom 200% nas 5 telas principais
- [ ] **AC4.2:** Verificar que não há truncamento, sobreposição ou perda de funcionalidade
- [ ] **AC4.3:** Ajustar layouts onde quebra (usar `rem`/`em` em vez de `px` fixo, etc.)

### AC5 — Reflow 320px (1.4.10)
- [ ] **AC5.1:** Viewport 320px → sem scroll horizontal
- [ ] **AC5.2:** Dashboard, /tasks, /tasks/new validados via Playwright em 320px
- [ ] **AC5.3:** Tabela de tarefas e resumo diário — verificar overflow horizontal controlado (`overflow-x-auto`)

### AC6 — Identificação consistente (3.2.4)
- [ ] **AC6.1:** Mapear todos os botões "Salvar", "Cancelar", "Excluir" → texto idêntico em telas similares
- [ ] **AC6.2:** Aria-labels consistentes ("Excluir tarefa NOME" em todas as listagens)

### AC7 — Mensagens de erro (3.3.3)
- [ ] **AC7.1:** Cada campo com erro de validação tem mensagem descritiva ("Nome deve ter no mínimo 3 caracteres")
- [ ] **AC7.2:** Erro associado ao campo via `aria-describedby` (já existe em vários — auditar)
- [ ] **AC7.3:** Sugestão de correção quando aplicável (ex: "Use formato DD/MM/AAAA")

### AC8 — Cobertura
- [ ] **AC8.1:** Specs existentes de accessibility atualizados para verificar contraste class (ex: `not text-gray-500 on bg-gray-800`)
- [ ] **AC8.2:** Spec axe-core no test (`axe-core-rspec` gem opcional) para 3 telas principais

### AC9 — Validação final
- [ ] **AC9.1:** axe DevTools mostra 0 issues nível AA nas 5 telas
- [ ] **AC9.2:** Lighthouse Accessibility score ≥ 95
- [ ] **AC9.3:** Navegação completa por teclado (login → criar Empresa → criar Project → criar Task → entregar)

---

## Análise Técnica

### Ferramentas

| Ferramenta | Uso |
|------------|-----|
| **axe DevTools** | Browser extension, scan estático |
| **Lighthouse** | Score de accessibility no Chrome DevTools |
| **WAVE** | Visualização de issues na página |
| **Pa11y CLI** | Automação em CI (opcional) |
| **axe-core-rspec** | Gem para integrar axe em system specs |

### Paleta Tailwind — pontos de atenção

Tailwind cinzas escuros + texto cinza claro:

| Combinação atual | Ratio | OK para AA? |
|------------------|-------|-------------|
| `text-gray-400` (`#9ca3af`) sobre `bg-gray-800` (`#1f2937`) | ~5.5:1 | ✅ |
| `text-gray-500` (`#6b7280`) sobre `bg-gray-800` (`#1f2937`) | ~3.6:1 | ❌ (precisa texto grande) |
| `text-gray-300` (`#d1d5db`) sobre `bg-gray-700` (`#374151`) | ~8:1 | ✅ |
| Badge `bg-yellow-500` text `text-white` | ~2.5:1 | ❌ — texto deve ser preto |

Auditoria detalhada gera lista de classes a substituir.

### Gem opcional

```ruby
group :test do
  gem "axe-core-rspec"
end
```

```ruby
# spec/system/accessibility_spec.rb
require "axe-rspec"

RSpec.describe "Accessibility", type: :system do
  it "dashboard atende WCAG 2.1 AA" do
    visit root_path
    expect(page).to be_axe_clean.according_to(:wcag2aa)
  end
end
```

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `wcag-aa-audit-findings.md` | Criar — resultado da auditoria |
| Vários `_*.html.erb` | Substituir classes Tailwind com contraste baixo |
| `app/views/layouts/application.html.erb` | Garantir focus ring global em links/botões |
| `app/views/shared/_flash.html.erb` | Texto preto sobre fundo amarelo/verde/vermelho |
| `app/components/status_badge_component.*` | Cores com contraste AA |
| `spec/system/accessibility_spec.rb` | Atualizar com `axe.according_to(:wcag2aa)` |
| `Gemfile` (opcional) | Adicionar `axe-core-rspec` |

---

## Testes

- [ ] axe DevTools nas 5 telas → 0 issues AA
- [ ] Lighthouse Accessibility ≥ 95 nas 5 telas
- [ ] System spec com axe passing
- [ ] Suite 1.120+ specs verde

---

## Observações

- **Foco em fluxos críticos:** login + onboarding + lançamento. Telas raramente usadas (perfil, password reset) podem ter menos rigor.
- **WCAG AAA** (próximo nível) exige contraste 7:1 — esforço desproporcional.
- **Compliance legal:** Brasil (Lei 13.146/2015 — LBI) referencia WCAG 2.1 AA para sites de utilidade pública. Para SaaS privado não é obrigatório, mas é diferencial competitivo.
- **Próximo passo opcional:** integrar Pa11y CLI no CI para regressão (story separada se for valioso).
