# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/minutely"

class Redis
  class MinutelySet < BaseSetObject
    include Minutely
  end
end
