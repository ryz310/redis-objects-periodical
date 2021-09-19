# frozen_string_literal: true

RSpec.describe Redis::HourlyCounter do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      hourly_counter :my_posts

      def id
        1
      end
    end
  end

  let(:instance) { MockClass.new }

  before do
    stub_const 'MockClass', mock_class
    Timecop.travel(Time.local(2021, 4, 1, 10))
    instance.my_posts.increment(10)
    Timecop.travel(Time.local(2021, 4, 1, 11))
    instance.my_posts.increment(11)
    Timecop.travel(Time.local(2021, 4, 1, 12))
    instance.my_posts.increment(12)
  end

  describe 'timezone' do
    before { Timecop.travel(Time.local(2021, 4, 1, 13)) }

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
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-01T10').to_i).to eq 10
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-01T11').to_i).to eq 11
      expect(instance.redis.get('mock_class:1:my_posts:2021-04-01T12').to_i).to eq 12
    end
  end

  describe '#value' do
    it 'returns the value counted today' do
      expect(instance.my_posts.value).to eq 12
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Time.local(2021, 4, 1, 10) }

      it 'returns the value counted the day' do
        expect(instance.my_posts[date]).to eq 10
      end
    end

    context 'with date and length' do
      let(:date) { Time.local(2021, 4, 1, 11) }

      it 'returns the values counted within the duration' do
        expect(instance.my_posts[date, 2]).to eq [11, 12]
      end
    end

    context 'with range' do
      let(:range) do
        Time.local(2021, 4, 1, 10)..Time.local(2021, 4, 1, 11)
      end

      it 'returns the values counted within the duration' do
        expect(instance.my_posts[range]).to eq [10, 11]
      end
    end
  end

  describe '#delete' do
    it 'deletes the value on the day' do
      date = Time.local(2021, 4, 1, 11)
      expect { instance.my_posts.delete(date) }
        .to change { instance.my_posts.at(date) }
        .from(11).to(0)
    end
  end

  describe '#range' do
    let(:start_date) { Time.local(2021, 4, 1, 10) }
    let(:end_date) { Time.local(2021, 4, 1, 11) }

    it 'returns the values counted within the duration' do
      expect(instance.my_posts.range(start_date, end_date)).to eq [10, 11]
    end
  end

  describe '#at' do
    let(:date) { Time.local(2021, 4, 1, 11) }

    it 'returns the value counted the day' do
      expect(instance.my_posts.at(date)).to eq 11
    end
  end
end
