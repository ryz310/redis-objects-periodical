# frozen_string_literal: true

RSpec.describe Redis::MinutelyValue do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      minutely_value :cache, expiration: 86_400 # about a day

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1, 10, 20))
    homepage.cache.value = 'a'
    Timecop.travel(Time.local(2021, 4, 1, 10, 21))
    homepage.cache.value = 'b'
    Timecop.travel(Time.local(2021, 4, 1, 10, 22))
    homepage.cache.value = 'c'
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        minutely_value :cache, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level increment/decrement of global values' do
      expect(homepage.redis.get('homepage::cache:2021-04-01T10:20')).to eq 'a'
      expect(homepage.redis.get('homepage::cache:2021-04-01T10:21')).to eq 'b'
      expect(homepage.redis.get('homepage::cache:2021-04-01T10:22')).to eq 'c'
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.cache.value = 'd'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.cache.value = 'd'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new values automatically with the current minute' do
      expect(homepage.redis.get('homepage:1:cache:2021-04-01T10:20')).to eq 'a'
      expect(homepage.redis.get('homepage:1:cache:2021-04-01T10:21')).to eq 'b'
      expect(homepage.redis.get('homepage:1:cache:2021-04-01T10:22')).to eq 'c'
    end
  end

  describe '#value' do
    it 'returns the value counted this minute' do
      expect(homepage.cache.value).to eq 'c'
    end
  end

  describe '#[]' do
    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20) }

      it 'returns the value counted the minute' do
        expect(homepage.cache[time]).to eq 'a'
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns the values counted within the duration' do
        expect(homepage.cache[time, 2]).to eq %w[b c]
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns an empty array' do
        expect(homepage.cache[time, 0]).to eq []
      end
    end

    context 'with range' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20)..Time.local(2021, 4, 1, 10, 21)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.cache[range]).to eq %w[a b]
      end
    end
  end

  describe '#delete_at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'deletes the value on the minute' do
      expect { homepage.cache.delete_at(time) }
        .to change { homepage.cache.at(time).value }
        .from('b').to(nil)
    end
  end

  describe '#range' do
    let(:start_time) { Time.local(2021, 4, 1, 10, 20) }
    let(:end_time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns the values counted within the duration' do
      expect(homepage.cache.range(start_time, end_time)).to eq %w[a b]
    end
  end

  describe '#at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns a value object counted the minute' do
      expect(homepage.cache.at(time).value).to eq 'b'
    end
  end
end
