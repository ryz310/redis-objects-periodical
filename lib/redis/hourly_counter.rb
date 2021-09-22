# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_counter_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/hourly"

class Redis
  class HourlyCounter < BaseCounterObject
    include Hourly
  end
end
