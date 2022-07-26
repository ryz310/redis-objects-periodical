# frozen_string_literal: true

require 'redis-objects'

class Redis
  PERIODICALS = %w[daily weekly monthly annual hourly minutely].freeze

  PERIODICALS.each do |periodical|
    autoload :"#{periodical.capitalize}Counter", 'redis/periodical_counter'
    autoload :"#{periodical.capitalize}HashKey", 'redis/periodical_hash_key'
    autoload :"#{periodical.capitalize}Set", 'redis/periodical_set'
  end

  module Objects
    PERIODICALS.each do |periodical|
      autoload :"#{periodical.capitalize}Counters", 'redis/objects/periodical_counters'
      autoload :"#{periodical.capitalize}Hashes", 'redis/objects/periodical_hashes'
      autoload :"#{periodical.capitalize}Sets", 'redis/objects/periodical_sets'
    end

    class << self
      alias original_included included

      def included(klass)
        original_included(klass)

        # Pull in each object type
        PERIODICALS.each do |periodical|
          klass.send :include, const_get("Redis::Objects::#{periodical.capitalize}Counters")
          klass.send :include, const_get("Redis::Objects::#{periodical.capitalize}Hashes")
          klass.send :include, const_get("Redis::Objects::#{periodical.capitalize}Sets")
        end
      end
    end
  end
end
