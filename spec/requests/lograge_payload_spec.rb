require 'rails_helper'

# Story 11.1 — DM-010 (AC4.1, AC4.2).
# Valida os dados customizados que ApplicationController#append_info_to_payload
# injeta no payload de process_action.action_controller — exatamente o payload
# que o Lograge lê via custom_options em production.rb.
RSpec.describe "Lograge custom payload", type: :request do
  let!(:user) { User.create!(email: "test@example.com", password: "password123") }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  # Captura o payload do último process_action.action_controller emitido
  # durante o bloco. É a mesma fonte que o Lograge consome.
  def capture_action_payload
    captured = nil
    subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
      captured = ActiveSupport::Notifications::Event.new(*args).payload
    end
    yield
    captured
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe "#append_info_to_payload" do
    it "inclui user_id, request_id e ip quando autenticado (AC4.1, AC2.1)" do
      sign_in(user)

      payload = capture_action_payload { get companies_path }

      expect(payload[:user_id]).to eq(user.id)
      expect(payload[:request_id]).to be_present
      expect(payload[:ip]).to be_present
    end

    it "retorna user_id nil quando não autenticado (AC4.2)" do
      # Endpoint público: a raiz redireciona para login, mas o payload ainda
      # é emitido antes do redirect, com user_id nil.
      payload = capture_action_payload { get new_session_path }

      expect(payload[:user_id]).to be_nil
      expect(payload[:request_id]).to be_present
      expect(payload[:ip]).to be_present
    end
  end
end
