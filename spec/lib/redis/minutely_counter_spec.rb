# frozen_string_literal: true

RSpec.describe Redis::MinutelyCounter do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      minutely_counter :pv, expiration: 86_400 # about a day

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1, 10, 20))
    homepage.pv.increment(10)
    Timecop.travel(Time.local(2021, 4, 1, 10, 21))
    homepage.pv.increment(11)
    Timecop.travel(Time.local(2021, 4, 1, 10, 22))
    homepage.pv.increment(12)
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        minutely_counter :pv, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level increment/decrement of global counters' do
      expect(homepage.redis.get('homepage::pv:2021-04-01T10:20').to_i).to eq 10
      expect(homepage.redis.get('homepage::pv:2021-04-01T10:21').to_i).to eq 11
      expect(homepage.redis.get('homepage::pv:2021-04-01T10:22').to_i).to eq 12
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.pv.increment(13)
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.pv.increment(13)
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new counters automatically with the current minute' do
      expect(homepage.redis.get('homepage:1:pv:2021-04-01T10:20').to_i).to eq 10
      expect(homepage.redis.get('homepage:1:pv:2021-04-01T10:21').to_i).to eq 11
      expect(homepage.redis.get('homepage:1:pv:2021-04-01T10:22').to_i).to eq 12
    end
  end

  describe '#value' do
    it 'returns the value counted this minute' do
      expect(homepage.pv.value).to eq 12
    end
  end

  describe '#[]' do
    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20) }

      it 'returns the value counted the minute' do
        expect(homepage.pv[time]).to eq 10
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv[time, 2]).to eq [11, 12]
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns an empty array' do
        expect(homepage.pv[time, 0]).to eq []
      end
    end

    context 'with range' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20)..Time.local(2021, 4, 1, 10, 21)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.pv[range]).to eq [10, 11]
      end
    end
  end

  describe '#delete_at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'deletes the value on the minute' do
      expect { homepage.pv.delete_at(time) }
        .to change { homepage.pv.at(time) }
        .from(11).to(0)
    end
  end

  describe '#range' do
    let(:start_time) { Time.local(2021, 4, 1, 10, 20) }
    let(:end_time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns the values counted within the duration' do
      expect(homepage.pv.range(start_time, end_time)).to eq [10, 11]
    end
  end

  describe '#at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns a counter object counted the minute' do
      expect(homepage.pv.at(time).value).to eq 11
    end
  end
end
