# frozen_string_literal: true

RSpec.describe Redis::Objects, '.prefix_style' do
  period_suffixes = {
    annual: '2026',
    monthly: '2026-10',
    weekly: '2026W43',
    daily: '2026-10-31',
    hourly: '2026-10-31T12',
    minutely: '2026-10-31T12:34',
  }
  object_types = %i[counter value set hash_key]
  global_options = [false, true]

  let(:model_class) do
    Class.new do
      include Redis::Objects

      def id
        7
      end
    end
  end

  around do |example|
    original_prefix_style = described_class.prefix_style
    described_class.prefix_style = prefix_style
    example.run
  ensure
    described_class.prefix_style = original_prefix_style
  end

  before do
    stub_const 'PrefixStyleExample::Entry0', model_class
    Timecop.freeze(Time.utc(2026, 10, 31, 12, 34))
  end

  {
    legacy: 'entry0',
    modern: 'prefix_style_example__entry0',
  }.each do |style, prefix|
    context "with prefix_style = #{style.inspect}" do
      let(:prefix_style) { style }

      period_suffixes.each do |period, suffix|
        object_types.each do |type|
          global_options.each do |global|
            context "with a #{period} #{type} and global: #{global}" do
              let(:record) { global ? model_class : model_class.new }
              let(:expected_key) do
                id = global ? nil : 7
                "#{prefix}:#{id}:metric:#{suffix}"
              end

              before do
                model_class.public_send("#{period}_#{type}", :metric, global: global)
              end

              it 'uses the selected prefix and period suffix for the persisted key' do
                object = record.metric
                write_value(object, type)

                expect(object.key).to eq expected_key
                expect(described_class.redis.exists?(expected_key)).to be true
              end
            end
          end
        end
      end
    end
  end

  def write_value(object, type)
    case type
    when :counter then object.increment
    when :value then object.value = 'sample'
    when :set then object << 'sample'
    when :hash_key then object['sample'] = 'value'
    end
  end
end
