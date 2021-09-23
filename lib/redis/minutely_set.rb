# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/minutely"

class Redis
  class MinutelySet < Set
    include RecurringAtIntervals
    include BaseSetObject
    include Minutely
  end
end
