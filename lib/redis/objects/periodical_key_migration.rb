# frozen_string_literal: true

class Redis
  # Shared model declarations and connection settings from redis-objects.
  module Objects
    # Migrates automatic prefixes while retaining complete periodical keys.
    module PeriodicalKeyMigration
      # An existing destination prevents the source key from being renamed.
      class Conflict < StandardError; end

      # Moves registered fields without changing their payloads or replacing destinations.
      # @api private
      class Migrator
        MOVE_KEY = <<~LUA
          if redis.call('EXISTS', KEYS[1]) == 0 then return 0 end
          if redis.call('RENAMENX', KEYS[1], KEYS[2]) == 0 then return -1 end
          return 1
        LUA

        def initialize(model, scan_count, verbose)
          @model = model
          @scan_count = scan_count
          @verbose = verbose
          @legacy = model.redis_legacy_prefix
          @modern = model.redis_modern_prefix
        end

        def call
          fields = migration_fields.reject { |_, options| options[:key] }
          fields.group_by { |_, options| options[:redis] || @model.redis }.each_value do |group|
            migrate_fields(group)
          end
          if @model.instance_variable_defined?(:@redis_prefix)
            @model.remove_instance_variable(:@redis_prefix)
          end
          nil
        end

        private

        def migration_fields
          @model.ancestors.reverse_each.with_object({}) do |ancestor, fields|
            if ancestor.is_a?(Class) && ancestor.respond_to?(:redis_objects)
              fields.merge!(ancestor.redis_objects)
            end
          end
        end

        def migrate_fields(fields)
          connection = @model.redis_field_redis(fields.first.first)
          patterns = fields.map do |name, options|
            id_pattern = options[:global] ? '' : '.+'
            /\A#{Regexp.escape(@legacy)}:#{id_pattern}:#{Regexp.escape(name.to_s)}(?::|\z)/
          end
          each_legacy_key(connection) do |key|
            migrate_key(connection, key) if patterns.any? { |pattern| pattern.match?(key) }
          end
        end

        def each_legacy_key(connection, &)
          cursor = '0'
          loop do
            cursor, keys = connection.scan(cursor, match: "#{@legacy}:*", count: @scan_count)
            keys.each(&)
            break if cursor == '0'
          end
        end

        def migrate_key(connection, key)
          new_key = @modern + key.delete_prefix(@legacy)
          result = connection.eval(MOVE_KEY, keys: [key, new_key])
          raise Conflict, "Migration destination already exists: #{new_key}" if result == -1

          warn "[redis-objects] Rename '#{key}', '#{new_key}'" if @verbose && result == 1
        end
      end

      # Retain the public positional argument signature supplied by redis-objects.
      # rubocop:disable-next Style/OptionalBooleanParameter
      def migrate_redis_legacy_keys(scan_count = 10, verbose = false)
        unless Objects.redis_legacy_naming?
          raise 'Redis::Objects is already configured to use modern key prefixes.'
        end
        unless scan_count.is_a?(Integer) && scan_count.positive?
          raise ArgumentError, 'scan_count must be a positive integer'
        end

        return if @silence_warnings_as_redis_prefix_was_set_manually && @redis_prefix
        return if redis_legacy_prefix == redis_modern_prefix

        Migrator.new(self, scan_count, verbose).call
      end
    end

    if ClassMethods.method_defined?(:migrate_redis_legacy_keys)
      ClassMethods.prepend(PeriodicalKeyMigration)
    end
  end
end
