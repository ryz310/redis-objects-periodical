# frozen_string_literal: true

RSpec.describe Redis::Objects::Daily::Counter do
  it 'has a version number' do
    expect(Redis::Objects::Daily::Counter::VERSION).not_to be nil
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

    describe 'keys' do
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

    describe '#[]' do
      context 'with date' do
        let(:date) { Date.new(2021, 4, 1) }

        it do
          expect(instance.my_posts[date]).to eq 10
        end
      end

      context 'with date and length' do
        let(:date) { Date.new(2021, 4, 2) }

        it do
          expect(instance.my_posts[date, 2]).to eq [11, 12]
        end
      end

      context 'with range' do
        let(:range) do
          Date.new(2021, 4, 1)..Date.new(2021, 4, 2)
        end

        it do
          expect(instance.my_posts[range]).to eq [10, 11]
        end
      end
    end

    describe '#delete' do
      it do
        date = Date.new(2021, 4, 2)
        expect { instance.my_posts.delete(date) }
          .to change { instance.my_posts.at(date) }
          .from(11).to(0)
      end
    end

    describe '#range' do
      let(:start_date) { Date.new(2021, 4, 1) }
      let(:end_date) { Date.new(2021, 4, 2) }

      it do
        expect(instance.my_posts.range(start_date, end_date)).to eq [10, 11]
      end
    end

    describe '#at' do
      let(:date) { Date.new(2021, 4, 2) }

      it do
        expect(instance.my_posts.at(date)).to eq 11
      end
    end
  end
end
