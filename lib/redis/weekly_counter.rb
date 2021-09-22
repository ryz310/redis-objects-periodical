# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_counter_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/weekly"

class Redis
  class WeeklyCounter < BaseCounterObject
    include Weekly
  end
end
