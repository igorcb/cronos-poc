# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidateEnvs do
  let(:logger) { instance_double(Logger, warn: nil) }

  # Config de teste isolada em arquivo temporário — não depende de config/required_envs.yml real.
  let(:config_yaml) do
    {
      'production' => {
        'required' => %w[FOO_REQUIRED BAR_REQUIRED],
        'optional' => %w[BAZ_OPTIONAL]
      }
    }
  end

  let(:config_path) do
    file = Tempfile.new(['required_envs', '.yml'])
    file.write(config_yaml.to_yaml)
    file.rewind
    file.path
  end

  def stub_env(present_keys)
    all_keys = %w[FOO_REQUIRED BAR_REQUIRED BAZ_OPTIONAL]
    allow(ENV).to receive(:[]).and_call_original
    all_keys.each do |key|
      allow(ENV).to receive(:[]).with(key).and_return(present_keys.include?(key) ? 'value' : nil)
    end
  end

  describe 'config/required_envs.yml (arquivo real)' do
    let(:real_config) do
      YAML.safe_load_file(Rails.root.join('config/required_envs.yml'))
    end

    it 'é parseável e tem as três seções de ambiente' do
      expect(real_config.keys).to include('production', 'development', 'test')
    end

    it 'declara production.required como Array com as ENVs críticas' do
      required = real_config['production']['required']
      expect(required).to be_an(Array)
      expect(required).to include(
        'RAILS_MASTER_KEY', 'DATABASE_URL', 'SECRET_KEY_BASE',
        'ADMIN_EMAIL', 'ADMIN_PASSWORD', 'INITIAL_TENANT_EMAIL'
      )
    end

    it 'declara production.optional como Array' do
      expect(real_config['production']['optional']).to be_an(Array)
    end
  end

  describe '.call' do
    context 'when environment is not production' do
      it 'returns early without reading the config (development)' do
        expect(YAML).not_to receive(:load_file)
        expect(described_class.call(env: 'development', config_path: config_path, logger: logger)).to be_nil
      end

      it 'returns early without reading the config (test)' do
        expect(YAML).not_to receive(:load_file)
        expect(described_class.call(env: 'test', config_path: config_path, logger: logger)).to be_nil
      end
    end

    context 'when environment is production' do
      context 'and a required ENV is missing' do
        before { stub_env(%w[FOO_REQUIRED BAZ_OPTIONAL]) }

        it 'raises listing all missing required ENVs, not only the first' do
          expect do
            described_class.call(env: 'production', config_path: config_path, logger: logger)
          end.to raise_error(RuntimeError, /BAR_REQUIRED/)
        end

        it 'includes the Railway configuration hint in the message' do
          expect do
            described_class.call(env: 'production', config_path: config_path, logger: logger)
          end.to raise_error(RuntimeError, /Railway dashboard/)
        end
      end

      context 'and multiple required ENVs are missing' do
        before { stub_env(%w[BAZ_OPTIONAL]) }

        it 'lists every missing required ENV' do
          expect do
            described_class.call(env: 'production', config_path: config_path, logger: logger)
          end.to raise_error(RuntimeError) { |e|
            expect(e.message).to include('FOO_REQUIRED', 'BAR_REQUIRED')
          }
        end
      end

      context 'and all required ENVs are present but an optional is missing' do
        before { stub_env(%w[FOO_REQUIRED BAR_REQUIRED]) }

        it 'does not raise' do
          expect do
            described_class.call(env: 'production', config_path: config_path, logger: logger)
          end.not_to raise_error
        end

        it 'warns on the logger for the missing optional ENV' do
          expect(logger).to receive(:warn).with('[boot] ENV opcional ausente: BAZ_OPTIONAL')
          described_class.call(env: 'production', config_path: config_path, logger: logger)
        end
      end

      context 'when DISABLE_DATABASE=1 (Docker build-time assets:precompile)' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DISABLE_DATABASE').and_return('1')
        end

        it 'skips validation entirely, does not read the config' do
          expect(YAML).not_to receive(:load_file)
          expect(described_class.call(env: 'production', config_path: config_path, logger: logger)).to be_nil
        end
      end

      context 'when SECRET_KEY_BASE_DUMMY=1 (Rails default build-time flag)' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DISABLE_DATABASE').and_return(nil)
          allow(ENV).to receive(:[]).with('SECRET_KEY_BASE_DUMMY').and_return('1')
        end

        it 'skips validation entirely, does not read the config' do
          expect(YAML).not_to receive(:load_file)
          expect(described_class.call(env: 'production', config_path: config_path, logger: logger)).to be_nil
        end
      end

      context 'and all ENVs (required and optional) are present' do
        before { stub_env(%w[FOO_REQUIRED BAR_REQUIRED BAZ_OPTIONAL]) }

        it 'boots OK without raising or warning' do
          expect(logger).not_to receive(:warn)
          expect do
            described_class.call(env: 'production', config_path: config_path, logger: logger)
          end.not_to raise_error
        end
      end
    end
  end
end
