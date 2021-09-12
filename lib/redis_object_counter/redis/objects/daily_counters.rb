# frozen_string_literal: true

class Redis
  module Objects
    module DailyCounters
      class << self
        def included(klass)
          klass.send :include, InstanceMethods
          klass.extend ClassMethods
        end
      end

      # Class methods that appear in your class when you include Redis::Objects.
      module ClassMethods
        # Define a new counter.  It will function like a regular instance
        # method, so it can be used alongside ActiveRecord, DataMapper, etc.
        def daily_counter(name, options = {})
          options[:start] ||= 0
          options[:type]  ||= options[:start] == 0 ? :increment : :decrement
          redis_objects[name.to_sym] = options.merge(type: :counter)

          mod = Module.new do
            define_method(name) do
              Redis::Counter.new(
                redis_daily_field_key(name), redis_field_redis(name), redis_options(name)
              )
            end
          end

          if options[:global]
            extend mod

            # dispatch to class methods
            define_method(name) do
              self.class.public_send(name)
            end
          else
            include mod
          end
        end
      end

      # Instance methods that appear in your class when you include Redis::Objects.
      module InstanceMethods
        def redis_daily_field_key(name, date = Date.today) #:nodoc:
          id = send(self.class.redis_id_field)
          "#{self.class.redis_field_key(name, id, self)}:#{date}"
        end
      end
    end
  end
end
