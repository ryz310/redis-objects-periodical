# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_hash_key_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/monthly"

class Redis
  class MonthlyHashKey < HashKey
    include RecurringAtIntervals
    include BaseHashKeyObject
    include Monthly
  end
end
