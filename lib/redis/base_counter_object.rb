# frozen_string_literal: true

class Redis
  module BaseCounterObject
    private

    def get_redis_object(key)
      Redis::Counter.new(key)
    end

    def get_value_from_redis(key)
      redis.get(key).to_i
    end

    def get_values_from_redis(keys)
      redis.mget(*keys).map(&:to_i)
    end

    def delete_from_redis(key)
      redis.del(key)
    end

    def empty_value
      []
    end
  end
end
