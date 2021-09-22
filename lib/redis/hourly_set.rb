# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/hourly"

class Redis
  class HourlySet < BaseSetObject
    include Hourly
  end
end
