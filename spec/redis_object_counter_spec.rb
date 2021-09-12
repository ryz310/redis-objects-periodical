# frozen_string_literal: true

RSpec.describe RedisObjectCounter do
  it 'has a version number' do
    expect(RedisObjectCounter::VERSION).not_to be nil
  end

  describe 'Redis::Objects' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects
        counter :my_posts

        def id
          1
        end
      end
    end

    it 'can use Redis::Objects' do
      instance = mock_class.new
      instance.my_posts.increment
      instance.my_posts.increment
      instance.my_posts.increment
      expect(instance.my_posts.value).to eq 3
    end
  end

  describe 'Redis::Objects::DailyCounters' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects
        include Redis::Objects::DailyCounters
        daily_counter :my_posts

        def id
          1
        end
      end
    end

    let(:instance) { mock_class.new }

    it do
      instance.my_posts.increment
      instance.my_posts.decrement
      instance.my_posts.increment
      instance.my_posts.increment
      expect(instance.my_posts.value).to eq 2
    end

    it do
      instance.my_posts.increment
      expect(instance.redis.get(':1:my_posts:2021-09-12').to_i).to eq 1
    end
  end
end
