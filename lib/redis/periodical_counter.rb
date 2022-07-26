# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_counter_object"

Redis::PERIODICALS.each do |periodical|
  require "#{File.dirname(__FILE__)}/recurring_at_intervals/#{periodical}"

  new_class = Class.new(Redis::Counter) do
    include Redis::RecurringAtIntervals
    include Redis::BaseCounterObject
    include const_get("Redis::RecurringAtIntervals::#{periodical.capitalize}")
  end
  Redis.const_set("#{periodical.capitalize}Counter", new_class)
end
