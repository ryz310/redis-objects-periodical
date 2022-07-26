# frozen_string_literal: true

require 'redis/periodical_counter'

Redis::PERIODICALS.each do |periodical| # rubocop:disable Metrics/BlockLength
  new_module = Module.new
  new_module.module_eval <<~RUBY, __FILE__, __LINE__ + 1
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def #{periodical}_counter(name, options = {})
        options[:start] ||= 0
        options[:type]  ||= (options[:start]).zero? ? :increment : :decrement
        redis_objects[name.to_sym] = options.merge(type: :counter)

        mod = Module.new do
          define_method(name) do
            Redis::#{periodical.capitalize}Counter.new(
              redis_field_key(name), redis_field_redis(name), redis_options(name)
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
  RUBY
  Redis::Objects.const_set("#{periodical.capitalize}Counters", new_module)
end
