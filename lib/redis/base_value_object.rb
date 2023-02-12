# frozen_string_literal: true

class Redis
  module BaseValueObject
    private

    def get_redis_object(key)
      Redis::Value.new(key)
    end

    def get_value_from_redis(key)
      unmarshal(redis.get(key))
    end

    def get_values_from_redis(keys)
      redis.mget(*keys).map { |v| unmarshal(v) }
    end

    def delete_from_redis(key)
      redis.del(key)
    end

    def empty_value
      []
    end
  end
end
