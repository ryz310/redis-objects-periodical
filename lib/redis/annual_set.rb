# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/annual"

class Redis
  class AnnualSet < Set
    include RecurringAtIntervals
    include BaseSetObject
    include Annual
  end
end
