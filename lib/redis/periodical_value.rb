# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_value_object"

Redis::PERIODICALS.each do |periodical|
  require "#{File.dirname(__FILE__)}/recurring_at_intervals/#{periodical}"

  new_class = Class.new(Redis::Value) do
    include Redis::RecurringAtIntervals
    include Redis::BaseValueObject
    include const_get("Redis::RecurringAtIntervals::#{periodical.capitalize}")
  end
  Redis.const_set("#{periodical.capitalize}Value", new_class)
end
