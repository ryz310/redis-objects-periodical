# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_counter_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/monthly"

class Redis
  class MonthlyCounter < BaseCounterObject
    include Monthly
  end
end
