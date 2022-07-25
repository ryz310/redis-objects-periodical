# frozen_string_literal: true

class Redis
  module BaseHashKeyObject
    private

    def get_redis_object(key)
      Redis::HashKey.new(key)
    end

    def get_value_from_redis(key)
      h = redis.hgetall(key) || {}
      h.each { |k, v| h[k] = unmarshal(v, options[:marshal_keys][k]) }
      h
    end

    def get_values_from_redis(keys) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      keys.inject({}) do |memo, key|
        memo.merge(get_value_from_redis(key)) do |_, self_val, other_val|
          values = [self_val, other_val]
          if values.all? { |val| val =~ /\A\d+\z/ }
            values.sum(&:to_i).to_s
          elsif values.all? { |val| val =~ /\A\d+(\.\d+)?\z/ }
            values.sum(&:to_f).to_s
          else
            values.join(',')
          end
        end
      end
    end

    def delete_from_redis(key)
      redis.del(key)
    end

    def empty_value
      {}
    end
  end
end
