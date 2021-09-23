# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/daily"

class Redis
  class DailySet < Set
    include RecurringAtIntervals
    include BaseSetObject
    include Daily
  end
end
