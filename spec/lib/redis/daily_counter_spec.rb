# frozen_string_literal: true

RSpec.describe Redis::DailyCounter do
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

  describe 'timezone' do
    before { Timecop.travel(Time.local(2021, 4, 4)) }

    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        instance.my_posts.increment(13)
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        instance.my_posts.increment(13)
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new counters automatically with the current date' do
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-01').to_i).to eq 10
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-02').to_i).to eq 11
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-03').to_i).to eq 12
    end
  end

  describe '#value' do
    it 'returns the value counted today' do
      expect(instance.my_posts.value).to eq 12
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the value counted the day' do
        expect(instance.my_posts[date]).to eq 10
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns the values counted within the duration' do
        expect(instance.my_posts[date, 2]).to eq [11, 12]
      end
    end

    context 'with range' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2021, 4, 2)
      end

      it 'returns the values counted within the duration' do
        expect(instance.my_posts[range]).to eq [10, 11]
      end
    end
  end

  describe '#delete' do
    it 'deletes the value on the day' do
      date = Date.new(2021, 4, 2)
      expect { instance.my_posts.delete(date) }
        .to change { instance.my_posts.at(date) }
        .from(11).to(0)
    end
  end

  describe '#range' do
    let(:start_date) { Date.new(2021, 4, 1) }
    let(:end_date) { Date.new(2021, 4, 2) }

    it 'returns the values counted within the duration' do
      expect(instance.my_posts.range(start_date, end_date)).to eq [10, 11]
    end
  end

  describe '#at' do
    let(:date) { Date.new(2021, 4, 2) }

    it 'returns the value counted the day' do
      expect(instance.my_posts.at(date)).to eq 11
    end
  end
end
