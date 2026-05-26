require "rails_helper"

# Story 9.3 — DM-008: Partial reutilizável de cada passo do onboarding.
RSpec.describe "onboarding/_step.html.erb", type: :view do
  def base_locals_for(number)
    {
      number: number,
      title: "Passo X — Título",
      description: "Descrição do passo",
      cta: "Executar Passo",
      path: "/exemplo/#{number}"
    }
  end

  # QA #L3 — parametrizar por number garante que `step_#{number}` não está hardcoded.
  [ 1, 2, 3 ].each do |n|
    context "estado :pending com number: #{n}" do
      before { render partial: "onboarding/step", locals: base_locals_for(n).merge(state: :pending) }

      it "renderiza link para o path com data-onboarding-cta=step_#{n}" do
        expect(rendered).to match(/<a[^>]*data-onboarding-cta="step_#{n}"[^>]*href="\/exemplo\/#{n}"/)
      end

      it "marca aria-label como passo atual" do
        expect(rendered).to include("aria-label=\"Passo #{n} (atual)\"")
      end

      it "exibe o número do passo no badge" do
        expect(rendered).to match(/>\s*#{n}\s*</)
      end
    end

    context "estado :locked com number: #{n}" do
      before { render partial: "onboarding/step", locals: base_locals_for(n).merge(state: :locked) }

      it "renderiza span com aria-disabled e role button (sem link)" do
        expect(rendered).to include('aria-disabled="true"')
        expect(rendered).to include('role="button"')
        expect(rendered).not_to match(/href="\/exemplo\/#{n}"/)
      end

      it "marca aria-label como bloqueado" do
        expect(rendered).to include("aria-label=\"Passo #{n} bloqueado\"")
      end

      it "mostra texto 'Bloqueado'" do
        expect(rendered).to include("Bloqueado")
      end
    end

    context "estado :done com number: #{n}" do
      before { render partial: "onboarding/step", locals: base_locals_for(n).merge(state: :done) }

      it "renderiza ícone de check e texto 'Concluído'" do
        expect(rendered).to include("Concluído")
      end

      it "marca aria-label como concluído" do
        expect(rendered).to include("aria-label=\"Passo #{n} concluído\"")
      end

      it "não renderiza link de CTA nem span de bloqueio" do
        expect(rendered).not_to match(/href="\/exemplo\/#{n}"/)
        expect(rendered).not_to include("Bloqueado")
      end
    end
  end

  # QA #L4 — estado inválido deve falhar alto, não silenciosamente.
  context "estado desconhecido" do
    it "levanta erro com causa ArgumentError" do
      expect {
        render partial: "onboarding/step", locals: base_locals_for(1).merge(state: :unknown_state)
      }.to raise_error(ActionView::Template::Error, /estado de onboarding desconhecido/)
    end
  end

  # QA #M5 — atributo data-onboarding-state existe como hook de teste para request specs;
  # garantir que aparece em todos os estados válidos.
  context "data-onboarding-state hook (QA #M5)" do
    it "renderiza o valor do estado como data-attribute" do
      render partial: "onboarding/step", locals: base_locals_for(1).merge(state: :pending)
      expect(rendered).to include('data-onboarding-state="pending"')

      render partial: "onboarding/step", locals: base_locals_for(2).merge(state: :locked)
      expect(rendered).to include('data-onboarding-state="locked"')

      render partial: "onboarding/step", locals: base_locals_for(3).merge(state: :done)
      expect(rendered).to include('data-onboarding-state="done"')
    end
  end
end
