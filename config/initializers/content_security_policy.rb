# Be sure to restart your server when you modify this file.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :none
    policy.base_uri        :self
    policy.script_src      :self                      # bundle em /assets; inline só via nonce
    policy.style_src       :self                      # <style> inline só via nonce (Turbo progress bar)
    policy.style_src_attr  :unsafe_inline             # style="..." em flash/forms (migrar p/ Tailwind)
    policy.img_src         :self, :data, "https://*.googleusercontent.com" # avatar Google
    policy.font_src        :self, :data
    policy.connect_src     :self                      # fetch, EventSource, ActionCable same-origin
    policy.form_action     :self, "https://accounts.google.com" # OAuth redireciona p/ Google
    policy.frame_ancestors :none
    policy.object_src      :none
    policy.manifest_src    :self
  end

  # Nonce por request (Turbo usa <meta name="csp-nonce"> para ativar scripts de frames/streams).
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report-only por padrão; em produção vira enforce com CSP_ENFORCE=true.
  config.content_security_policy_report_only = !(Rails.env.production? && ENV["CSP_ENFORCE"] == "true")
end
