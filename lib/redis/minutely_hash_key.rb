# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_hash_key_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/minutely"

class Redis
  class MinutelyHashKey < HashKey
    include RecurringAtIntervals
    include BaseHashKeyObject
    include Minutely
  end
end
