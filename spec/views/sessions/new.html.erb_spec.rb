require 'rails_helper'

RSpec.describe "sessions/new.html.erb", type: :view do
  # QA finding 9.1 #4 HIGH — view e initializer usam mesmo guard (CLIENT_ID + SECRET).
  # QA finding 9.1 #10 MEDIUM — around com ensure restaura ENV mesmo em failure.
  context "when GOOGLE OAuth credentials are present" do
    around do |example|
      original_id = ENV["GOOGLE_CLIENT_ID"]
      original_secret = ENV["GOOGLE_CLIENT_SECRET"]
      ENV["GOOGLE_CLIENT_ID"] = "fake-client-id"
      ENV["GOOGLE_CLIENT_SECRET"] = "fake-secret"
      example.run
    ensure
      ENV["GOOGLE_CLIENT_ID"] = original_id
      ENV["GOOGLE_CLIENT_SECRET"] = original_secret
    end

    it "renders the email/password form (no regression)" do
      render
      expect(rendered).to include("Email")
      expect(rendered).to include("Senha")
      expect(rendered).to include('type="email"')
      expect(rendered).to include('type="password"')
    end

    it "renders the 'ou' divider with role=separator (QA #7)" do
      render
      expect(rendered).to match(/role="separator"[^>]*aria-label="ou"|aria-label="ou"[^>]*role="separator"/)
      expect(rendered).to include(">ou<")
    end

    it "renders the Google sign-in button via button_to (POST)" do
      render
      expect(rendered).to include("Entrar com Google")
      expect(rendered).to include('action="/auth/google_oauth2"')
      expect(rendered).to include('method="post"')
    end

    it "includes the Google G icon with aria-hidden" do
      render
      # Asset fingerprinting adiciona hash entre google_g e .svg.
      # aria-hidden e src aparecem no mesmo <img> tag (a ordem pode variar).
      expect(rendered).to match(/<img[^>]*aria-hidden="true"[^>]*google_g[^>]*\.svg|<img[^>]*google_g[^>]*\.svg[^>]*aria-hidden="true"/)
    end
  end

  context "when GOOGLE_CLIENT_SECRET is missing (partial setup — QA #4)" do
    around do |example|
      original_id = ENV["GOOGLE_CLIENT_ID"]
      original_secret = ENV["GOOGLE_CLIENT_SECRET"]
      ENV["GOOGLE_CLIENT_ID"] = "fake-only-id"
      ENV.delete("GOOGLE_CLIENT_SECRET")
      example.run
    ensure
      ENV["GOOGLE_CLIENT_ID"] = original_id
      ENV["GOOGLE_CLIENT_SECRET"] = original_secret
    end

    it "does NOT render the Google button when SECRET is missing (graceful degradation)" do
      render
      expect(rendered).not_to include("Entrar com Google")
      expect(rendered).not_to include("/auth/google_oauth2")
    end
  end

  context "when both GOOGLE OAuth credentials are absent (graceful degradation)" do
    around do |example|
      original_id = ENV["GOOGLE_CLIENT_ID"]
      original_secret = ENV["GOOGLE_CLIENT_SECRET"]
      ENV.delete("GOOGLE_CLIENT_ID")
      ENV.delete("GOOGLE_CLIENT_SECRET")
      example.run
    ensure
      ENV["GOOGLE_CLIENT_ID"] = original_id
      ENV["GOOGLE_CLIENT_SECRET"] = original_secret
    end

    it "still renders the email/password form" do
      render
      expect(rendered).to include("Email")
      expect(rendered).to include("Senha")
    end

    it "does NOT render the Google sign-in button" do
      render
      expect(rendered).not_to include("Entrar com Google")
      expect(rendered).not_to include("/auth/google_oauth2")
    end

    it "does NOT render the 'ou' divider" do
      render
      expect(rendered).not_to include('role="separator"')
    end
  end
end
