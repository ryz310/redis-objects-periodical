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
        SUFFIXES = {
          annual: /-?\d{4,}/,
          monthly: /-?\d{4,}-\d{2}/,
          weekly: /-?\d{4,}W\d{2}/,
          daily: /-?\d{4,}-\d{2}-\d{2}/,
          hourly: /-?\d{4,}-\d{2}-\d{2}T\d{2}/,
          minutely: /-?\d{4,}-\d{2}-\d{2}T\d{2}:\d{2}/,
        }.freeze

        MOVE_KEY = <<~LUA
          if redis.call('EXISTS', KEYS[1]) == 0 then return 0 end
          if redis.call('RENAMENX', KEYS[1], KEYS[2]) == 0 then return -1 end
          return 1
        LUA

        def initialize(model, scan_count, verbose)
          @model = model
          @scan_count = scan_count
          @verbose = verbose
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
          migration_models.reverse_each.with_object({}) do |ancestor, fields|
            fields.merge!(ancestor.redis_objects)
          end
        end

        def migration_models
          @model.ancestors.select do |ancestor|
            ancestor.is_a?(Class) && ancestor.respond_to?(:redis_objects)
          end
        end

        def migration_prefixes
          prefixes = migration_models.map do |ancestor|
            [ancestor.redis_legacy_prefix, ancestor.redis_modern_prefix]
          end
          prefixes.uniq.reject { |legacy, modern| legacy == modern }
        end

        def migrate_fields(fields)
          connection = @model.redis_field_redis(fields.first.first)
          patterns = fields.map { |name, options| field_pattern(name, options) }
          migration_prefixes.each do |legacy, modern|
            each_legacy_key(connection, legacy) do |key|
              tail = key.delete_prefix("#{legacy}:")
              migrate_key(connection, key, legacy, modern) if patterns.any? { |p| p.match?(tail) }
            end
          end
        end

        def field_pattern(name, options)
          id_pattern = options[:global] ? '' : '.*'
          suffix = SUFFIXES[options[:periodical]]
          ending = suffix ? ":#{suffix}" : ''
          /\A#{id_pattern}:#{Regexp.escape(name.to_s)}#{ending}\z/m
        end

        def each_legacy_key(connection, legacy, &)
          cursor = '0'
          loop do
            cursor, keys = connection.scan(cursor, match: "#{legacy}:*", count: @scan_count)
            keys.each(&)
            break if cursor == '0'
          end
        end

        def migrate_key(connection, key, legacy, modern)
          new_key = modern + key.delete_prefix(legacy)
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

        Migrator.new(self, scan_count, verbose).call
      end
    end

    if ClassMethods.method_defined?(:migrate_redis_legacy_keys)
      ClassMethods.prepend(PeriodicalKeyMigration)
    end
  end
end
