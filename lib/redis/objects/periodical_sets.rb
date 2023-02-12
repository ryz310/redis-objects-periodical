# frozen_string_literal: true

require 'redis/periodical_set'

Redis::PERIODICALS.each do |periodical| # rubocop:disable Metrics/BlockLength
  new_module = Module.new
  new_module.module_eval <<~RUBY, __FILE__, __LINE__ + 1
    def self.included(klass)
      klass.extend ClassMethods
    end

    # Class methods that appear in your class when you include Redis::Objects.
    module ClassMethods
      # Define a new list.  It will function like a regular instance
      # method, so it can be used alongside ActiveRecord, DataMapper, etc.
      def #{periodical}_set(name, options = {})
        redis_objects[name.to_sym] = options.merge(type: :set)

        mod = Module.new do
          define_method(name) do
            Redis::#{periodical.capitalize}Set.new(
              redis_field_key(name), redis_field_redis(name), redis_options(name)
            )
          end

          define_method(:"#\{name}=") do |values|
            set = public_send(name)

            redis.pipelined do
              set.clear
              set.merge(*values)
            end
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
  Redis::Objects.const_set("#{periodical.capitalize}Sets", new_module)
end
