# frozen_string_literal: true

require 'redis/annual_set'
class Redis
  module Objects
    module AnnualSets
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Class methods that appear in your class when you include Redis::Objects.
      module ClassMethods
        # Define a new list.  It will function like a regular instance
        # method, so it can be used alongside ActiveRecord, DataMapper, etc.
        def annual_set(name, options={}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          redis_objects[name.to_sym] = options.merge(type: :set)

          mod = Module.new do
            define_method(name) do
              Redis::AnnualSet.new(
                redis_field_key(name), redis_field_redis(name), redis_options(name)
              )
            end

            define_method(:"#{name}=") do |values|
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
    end
  end
end
