# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_hash_key_object"

Redis::PERIODICALS.each do |periodical|
  require "#{File.dirname(__FILE__)}/recurring_at_intervals/#{periodical}"

  new_class = Class.new(Redis::HashKey) do
    include Redis::RecurringAtIntervals
    include Redis::BaseHashKeyObject
    include const_get("Redis::RecurringAtIntervals::#{periodical.capitalize}")
  end
  Redis.const_set(:"#{periodical.capitalize}HashKey", new_class)
end
