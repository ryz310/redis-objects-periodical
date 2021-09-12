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
    before { stub_const 'MockClass', mock_class }

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

    let(:instance) { MockClass.new }

    it do
      Timecop.travel(Time.local(2021, 4, 1))
      instance.my_posts.increment
      instance.my_posts.decrement
      instance.my_posts.increment(2)
      expect(instance.my_posts.value).to eq 2
      Timecop.travel(Time.local(2021, 4, 2))
      expect(instance.my_posts.value).to eq 0
    end

    it do
      Timecop.travel(Time.local(2021, 4, 1))
      instance.my_posts.increment
      Timecop.travel(Time.local(2021, 4, 2))
      instance.my_posts.increment(3)
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-01').to_i).to eq 1
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-02').to_i).to eq 3
    end

    describe '#sum' do
      it do
        Timecop.travel(Time.local(2021, 4, 1))
        instance.my_posts.increment(10)
        Timecop.travel(Time.local(2021, 4, 2))
        instance.my_posts.increment(11)
        Timecop.travel(Time.local(2021, 4, 3))
        instance.my_posts.increment(12)
        expect(instance.my_posts.sum(3)).to eq 33
      end
    end

    describe '#average' do
      it do
        Timecop.travel(Time.local(2021, 4, 1))
        instance.my_posts.increment(10)
        Timecop.travel(Time.local(2021, 4, 2))
        instance.my_posts.increment(11)
        Timecop.travel(Time.local(2021, 4, 3))
        instance.my_posts.increment(12)
        expect(instance.my_posts.average(3)).to eq 11.0
      end
    end
  end
end
