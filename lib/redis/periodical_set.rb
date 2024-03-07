# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_set_object"

Redis::PERIODICALS.each do |periodical|
  require "#{File.dirname(__FILE__)}/recurring_at_intervals/#{periodical}"

  new_class = Class.new(Redis::Set) do
    include Redis::RecurringAtIntervals
    include Redis::BaseSetObject
    include const_get("Redis::RecurringAtIntervals::#{periodical.capitalize}")
  end
  Redis.const_set(:"#{periodical.capitalize}Set", new_class)
end
