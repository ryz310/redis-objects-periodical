# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/monthly"

class Redis
  class MonthlySet < Set
    include RecurringAtIntervals
    include BaseSetObject
    include Monthly
  end
end