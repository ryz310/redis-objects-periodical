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

    let(:instance) { MockClass.new }

    before do
      stub_const 'MockClass', mock_class
      Timecop.travel(Time.local(2021, 4, 1))
      instance.my_posts.increment(10)
      Timecop.travel(Time.local(2021, 4, 2))
      instance.my_posts.increment(11)
      Timecop.travel(Time.local(2021, 4, 3))
      instance.my_posts.increment(12)
    end

    describe 'key' do
      it do
        expect(instance.redis.get('mock_class:1:my_posts:2021-04-01').to_i).to eq 10
        expect(instance.redis.get('mock_class:1:my_posts:2021-04-02').to_i).to eq 11
        expect(instance.redis.get('mock_class:1:my_posts:2021-04-03').to_i).to eq 12
      end
    end

    describe '#value' do
      it do
        expect(instance.my_posts.value).to eq 12
      end
    end

    describe '#get_value' do
      it do
        expect(instance.my_posts.get_value(Date.new(2021, 4, 1))).to eq 10
        expect(instance.my_posts.get_value(Date.new(2021, 4, 2))).to eq 11
        expect(instance.my_posts.get_value(Date.new(2021, 4, 3))).to eq 12
      end
    end

    describe '#values' do
      it do
        expect(instance.my_posts.values(3)).to eq [10, 11, 12]
      end
    end
  end
end
