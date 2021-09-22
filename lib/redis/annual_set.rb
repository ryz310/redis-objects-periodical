# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_set_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/annual"

class Redis
  class AnnualSet < BaseSetObject
    include Annual
  end
end
