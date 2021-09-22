# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/daily"

class Redis
  class DailySet < BaseSetObject
    include Daily
  end
end
