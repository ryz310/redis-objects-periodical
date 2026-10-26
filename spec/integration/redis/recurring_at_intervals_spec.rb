# frozen_string_literal: true

# Run explicitly in a separate process; normal specs exercise plain Ruby too.
require 'logger'
require 'active_support'
require 'active_support/time'
require 'redis/recurring_at_intervals'

RSpec.describe Redis::RecurringAtIntervals do
  periods = %w[annual monthly weekly daily hourly minutely]
  types = %i[counter value set hash_key]
  let(:model_class) do
    Class.new do
      include Redis::Objects

      periods.each do |period|
        types.each do |type|
          public_send("#{period}_#{type}", "#{period}_#{type}")
        end
      end

      def id
        1
      end
    end
  end

  let(:model) { TimezoneExample.new }

  before do
    stub_const 'TimezoneExample', model_class
  end

  {
    'year and month boundary' => {
      instant: Time.utc(2020, 12, 31, 23, 30),
      tokyo: %w[2021 2021-01 2020W52 2021-01-01 2021-01-01T08 2021-01-01T08:30],
      utc: %w[2020 2020-12 2020W52 2020-12-31 2020-12-31T23 2020-12-31T23:30],
    },
    'week boundary' => {
      instant: Time.utc(2021, 1, 3, 23, 30),
      tokyo: %w[2021 2021-01 2021W01 2021-01-04 2021-01-04T08 2021-01-04T08:30],
      utc: %w[2021 2021-01 2020W52 2021-01-03 2021-01-03T23 2021-01-03T23:30],
    },
  }.each do |boundary, fixture|
    context "when crossing the #{boundary}" do
      before { Timecop.freeze(fixture.fetch(:instant)) }

      { 'Asia/Tokyo' => fixture.fetch(:tokyo), nil => fixture.fetch(:utc) }.each do |zone, suffixes|
        context "with Time.zone = #{zone.inspect}" do
          around do |example|
            Time.use_zone(zone) { example.run }
          end

          periods.zip(suffixes).each do |period, suffix|
            types.each do |type|
              it "persists the #{period} #{type} in the selected timezone" do
                field = "#{period}_#{type}"
                object = model.public_send(field)
                expected_key = "timezone_example:1:#{field}:#{suffix}"
                write_value(object, type)

                expect(object.key).to eq expected_key
                expect(object.current_time).to eq Time.current
                expect(Redis::Objects.redis.exists?(expected_key)).to be true
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
