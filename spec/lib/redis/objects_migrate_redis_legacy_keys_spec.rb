# frozen_string_literal: true

require 'connection_pool'

RSpec.describe Redis::Objects, '.migrate_redis_legacy_keys' do
  period_suffixes = {
    annual: %w[2025 2026],
    monthly: %w[2026-09 2026-10],
    weekly: %w[2026W42 2026W43],
    daily: %w[2026-10-30 2026-10-31],
    hourly: %w[2026-10-31T11 2026-10-31T12],
    minutely: %w[2026-10-31T12:33 2026-10-31T12:34],
  }
  object_types = %i[counter value set hash_key]
  global_options = [false, true]
  cached_options = [true, false]

  let(:model_name) { 'MigrationExample::Entry0' }
  let(:connection) { described_class.redis }
  let(:model_class) do
    Class.new do
      include Redis::Objects

      def id
        7
      end
    end
  end

  around do |example|
    original_style = described_class.prefix_style
    described_class.prefix_style = :legacy
    example.run
  ensure
    described_class.prefix_style = original_style
  end

  before do
    stub_const model_name, model_class
    model_class.redis_silence_warnings = true
    Timecop.freeze(Time.utc(2026, 10, 31, 12, 34))
  end

  period_suffixes.each do |period, suffixes|
    object_types.each do |type|
      global_options.each do |global|
        context "with a #{period} #{type} and global: #{global}" do
          let(:old_keys) do
            id = global ? nil : 7
            suffixes.map { |suffix| "entry0:#{id}:metric:#{suffix}" }
          end
          let(:new_keys) do
            id = global ? nil : 7
            suffixes.map { |suffix| "migration_example__entry0:#{id}:metric:#{suffix}" }
          end

          before do
            model_class.public_send("#{period}_#{type}", :metric, global: global)
            write_keys(old_keys, type)
            custom_key = "#{old_keys.first.delete_suffix(":#{suffixes.first}")}:archive"
            model_class.public_send("#{period}_value", :archive, key: custom_key, global: global)
            model_class.new.archive.value = 'fixed'
          end

          it 'preserves periods, payloads, expirations, and overlapping custom keys' do
            snapshots = old_keys.map { |key| connection.dump(key) }
            model_class.migrate_redis_legacy_keys(1)

            expect(new_keys.map { |key| connection.dump(key) }).to eq snapshots
            expect(old_keys.map { |key| connection.exists?(key) }).to eq [false, false]
            expect(new_keys.map { |key| connection.pttl(key) }).to all(be_between(1, 60_000))
            described_class.prefix_style = :modern
            expect(model_class.new.archive.value).to eq 'fixed'
          end
        end
      end
    end
  end

  context 'with daily counters' do
    let(:old_key) { 'entry0:7:metric:2026-10-31' }
    let(:new_key) { 'migration_example__entry0:7:metric:2026-10-31' }

    before do
      model_class.daily_counter :metric
      connection.set(old_key, 17)
    end

    it 'clears the cached automatic prefix for the subsequent modern switch' do
      retained = model_class.new.metric
      model_class.migrate_redis_legacy_keys
      described_class.prefix_style = :modern

      expect(model_class.new.metric.key).to eq new_key
      expect(model_class.new.metric.value).to eq 17
      expect(retained.key).to eq old_key
    end

    it 'also migrates ordinary fields without touching unknown fields' do
      model_class.counter :total
      connection.mset('entry0:7:total', 29, 'entry0:7:unknown', 'keep')
      model_class.migrate_redis_legacy_keys

      expect(connection.mget(new_key, 'migration_example__entry0:7:total')).to eq %w[17 29]
      expect(connection.get('entry0:7:unknown')).to eq 'keep'
    end

    it 'preserves the prefix style when refusing migration in modern mode' do
      described_class.prefix_style = :modern

      expect { model_class.migrate_redis_legacy_keys }
        .to raise_error(RuntimeError, /already configured/)
      expect(described_class.prefix_style).to eq :modern
      expect(connection.get(old_key)).to eq '17'
    end

    it 'rejects an invalid scan count before changing any keys' do
      expect { model_class.migrate_redis_legacy_keys(0) }.to raise_error(ArgumentError)
      expect(connection.get(old_key)).to eq '17'
    end

    it 'logs individual renames only when verbose is requested' do
      expect { model_class.migrate_redis_legacy_keys(1, true) }
        .to output(/Rename '#{Regexp.escape(old_key)}', '#{Regexp.escape(new_key)}'/).to_stderr
    end

    it 'continues scanning until the returned cursor is zero' do
      second_key = 'entry0:7:metric:2026-10-30'
      connection.set(second_key, 23)
      allow(connection).to receive(:scan).and_return(['9', [old_key]], ['0', [second_key]])
      model_class.migrate_redis_legacy_keys(1)

      expect(connection.mget(new_key, 'migration_example__entry0:7:metric:2026-10-30'))
        .to eq %w[17 23]
      expect(connection).to have_received(:scan).with('9', match: 'entry0:*', count: 1)
    end

    it 'tolerates duplicate scan entries and keys that have expired since scanning' do
      missing = 'entry0:7:metric:2026-10-30'
      allow(connection).to receive(:scan).and_return(['0', [old_key, old_key, missing]])

      expect { model_class.migrate_redis_legacy_keys }.not_to raise_error
      expect(connection.get(new_key)).to eq '17'
    end

    context 'with an existing destination' do
      before { connection.set(new_key, 99) }

      it 'raises without overwriting the source or destination' do
        expect { model_class.migrate_redis_legacy_keys }
          .to raise_error(Redis::Objects::PeriodicalKeyMigration::Conflict, /already exists/)
        expect(connection.mget(old_key, new_key)).to eq %w[17 99]
        expect(described_class.prefix_style).to eq :legacy
      end
    end

    context 'with a collision after an earlier rename' do
      before do
        connection.set('entry0:7:metric:2026-10-30', 23)
        connection.set('migration_example__entry0:7:metric:2026-10-30', 99)
        allow(connection).to receive(:scan)
          .and_return(['0', [old_key, 'entry0:7:metric:2026-10-30']])
      end

      it 'can resume after the destination collision has been resolved' do
        expect { model_class.migrate_redis_legacy_keys }
          .to raise_error(Redis::Objects::PeriodicalKeyMigration::Conflict)
        connection.del('migration_example__entry0:7:metric:2026-10-30')
        model_class.migrate_redis_legacy_keys

        expect(connection.mget(new_key, 'migration_example__entry0:7:metric:2026-10-30'))
          .to eq %w[17 23]
      end
    end

    context 'with an explicit model prefix matching the legacy prefix' do
      before { model_class.redis_prefix = 'entry0' }

      it 'leaves the fixed prefix and its keys unchanged' do
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.metric.key).to eq old_key
        expect(connection.get(old_key)).to eq '17'
        expect(connection.exists?(new_key)).to be false
      end
    end

    context 'with explicit field keys' do
      before do
        model_class.daily_value :custom, key: 'entry0:7:custom'
        model_class.daily_value :callable, key: ->(record) { "entry0:#{record.id}:callable" }
        model_class.new.custom.value = 'fixed'
        model_class.new.callable.value = 'callable'
      end

      it 'keeps string and callable keys while migrating automatic keys' do
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.custom.value).to eq 'fixed'
        expect(model_class.new.callable.value).to eq 'callable'
        expect(model_class.new.metric.value).to eq 17
      end

      it 'preserves a custom key extending an automatic field key' do
        model_class.daily_value :archive, key: 'entry0:7:metric:archive'
        model_class.new.archive.value = 'fixed'
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.archive.value).to eq 'fixed'
        expect(model_class.new.metric.value).to eq 17
      end

      it 'requires ordinary automatic fields to end at the field name' do
        model_class.counter :total
        model_class.daily_value :archive, key: 'entry0:7:total:archive'
        model_class.new.total.increment(29)
        model_class.new.archive.value = 'fixed'
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.total.value).to eq 29
        expect(model_class.new.archive.value).to eq 'fixed'
      end
    end

    context 'with a pooled field connection' do
      before do
        pool = ConnectionPool.new(size: 1) { Redis.new(host: 'redis', port: 6379, db: 1) }
        model_class.daily_counter :metric, redis: pool
        model_class.redis_field_redis(:metric).flushdb
        model_class.redis_field_redis(:metric).set(old_key, 23)
      end

      after do
        model_class.redis_field_redis(:metric).flushdb
        model_class.redis_options(:metric).fetch(:redis).shutdown(&:close)
      end

      it 'migrates that field on its configured connection only' do
        model_class.migrate_redis_legacy_keys

        expect(model_class.redis_field_redis(:metric).get(new_key)).to eq '23'
        expect(model_class.redis_field_redis(:metric).exists?(old_key)).to be false
        expect(connection.get(old_key)).to eq '17'
        expect(connection.exists?(new_key)).to be false
      end
    end

    context 'with a global field' do
      let(:old_key) { 'entry0::metric:2026-10-31' }
      let(:new_key) { 'migration_example__entry0::metric:2026-10-31' }

      before { model_class.daily_counter :metric, global: true }

      it 'makes the migrated value readable after switching styles' do
        model_class.metric
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.metric.key).to eq new_key
        expect(model_class.metric.value).to eq 17
      end
    end

    context 'with inherited fields sharing the model prefix' do
      let(:model_class) do
        parent = Class.new do
          include Redis::Objects

          counter :inherited
        end
        Class.new(parent) do
          def id
            7
          end
        end
      end

      it 'includes inherited declarations when migrating the child prefix' do
        model_class.new.metric
        model_class.new.inherited.increment(31)
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern
        model_class.new.metric

        expect(model_class.new.inherited.value).to eq 31
        expect(connection.get('migration_example__entry0:7:inherited')).to eq '31'
      end
    end

    context 'with a colon in the record ID' do
      let(:old_key) { 'entry0:org:7:metric:2026-10-31' }
      let(:new_key) { 'migration_example__entry0:org:7:metric:2026-10-31' }

      before { model_class.define_method(:id) { 'org:7' } }

      it 'retains the complete ID and period suffix' do
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.metric.key).to eq new_key
        expect(model_class.new.metric.value).to eq 17
      end
    end

    context 'with an empty string record ID' do
      let(:old_key) { 'entry0::metric:2026-10-31' }
      let(:new_key) { 'migration_example__entry0::metric:2026-10-31' }

      before { model_class.define_method(:id) { '' } }

      it 'retains the stored value after switching styles' do
        model_class.new.metric.increment(6)
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.metric.key).to eq new_key
        expect(model_class.new.metric.value).to eq 23
        expect(connection.exists?(old_key)).to be false
      end
    end

    context 'when an inherited field selected the parent prefix first' do
      let(:model_class) do
        parent = Class.new do
          include Redis::Objects

          daily_counter :inherited

          def id
            7
          end
        end
        stub_const 'MigrationExample::Parent', parent
        parent.redis_silence_warnings = true
        Class.new(parent)
      end

      before do
        connection.del(old_key)
        model_class.new.inherited.increment(31)
        model_class.new.metric.increment(17)
      end

      [%i[parent child], %i[child parent]].each do |order|
        cached_options.each do |cached|
          it "migrates in #{order.join('/')} order with cached prefix: #{cached}" do
            expect(model_class.new.metric.key).to eq 'parent:7:metric:2026-10-31'
            model_class.remove_instance_variable(:@redis_prefix) unless cached
            models = { parent: model_class.superclass, child: model_class }
            order.each { |name| models.fetch(name).migrate_redis_legacy_keys }
            described_class.prefix_style = :modern

            expect(model_class.new.inherited.value).to eq 31
            expect(model_class.new.metric.value).to eq 17
            expect(connection.exists?('parent:7:metric:2026-10-31')).to be false
          end
        end
      end
    end

    context 'with a top-level model' do
      let(:model_name) { 'MigrationEntry0' }
      let(:old_key) { 'migration_entry0:7:metric:2026-10-31' }

      it 'does not change keys whose prefix is identical in both styles' do
        model_class.migrate_redis_legacy_keys
        described_class.prefix_style = :modern

        expect(model_class.new.metric.key).to eq old_key
        expect(model_class.new.metric.value).to eq 17
      end
    end
  end

  def write_keys(keys, type)
    keys.each_with_index do |key, index|
      case type
      when :counter then connection.set(key, index + 17)
      when :value then connection.set(key, Marshal.dump(['value', index]))
      when :set then connection.sadd(key, Marshal.dump(['member', index]))
      when :hash_key then connection.hset(key, 'field', Marshal.dump(['value', index]))
      end
      connection.pexpire(key, 60_000)
    end
  end
end
