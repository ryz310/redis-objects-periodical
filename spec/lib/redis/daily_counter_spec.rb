# frozen_string_literal: true

RSpec.describe Redis::DailyCounter do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      daily_counter :pv, expiration: 2_678_400 # about a month

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1))
    homepage.pv.increment(10)
    Timecop.travel(Time.local(2021, 4, 2))
    homepage.pv.increment(11)
    Timecop.travel(Time.local(2021, 4, 3))
    homepage.pv.increment(12)
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        daily_counter :pv, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level increment/decrement of global counters' do
      expect(homepage.redis.get('homepage::pv:2021-04-01').to_i).to eq 10
      expect(homepage.redis.get('homepage::pv:2021-04-02').to_i).to eq 11
      expect(homepage.redis.get('homepage::pv:2021-04-03').to_i).to eq 12
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
    it 'appends new counters automatically with the current date' do
      expect(homepage.redis.get('homepage:1:pv:2021-04-01').to_i).to eq 10
      expect(homepage.redis.get('homepage:1:pv:2021-04-02').to_i).to eq 11
      expect(homepage.redis.get('homepage:1:pv:2021-04-03').to_i).to eq 12
    end
  end

  describe '#value' do
    it 'returns the value counted today' do
      expect(homepage.pv.value).to eq 12
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the value counted the day' do
        expect(homepage.pv[date]).to eq 10
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv[date, 2]).to eq [11, 12]
      end
    end

    context 'with date and length (zero)' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns an empty array' do
        expect(homepage.pv[date, 0]).to eq []
      end
    end

    context 'with range of date' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2021, 4, 2)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.pv[range]).to eq [10, 11]
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20, 30) }

      it 'returns the value counted the day' do
        expect(homepage.pv[time]).to eq 10
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv[time, 2]).to eq [11, 12]
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns an empty array' do
        expect(homepage.pv[time, 0]).to eq []
      end
    end

    context 'with range of time' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20, 30)..Time.local(2021, 4, 2, 10, 20, 30)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.pv[range]).to eq [10, 11]
      end
    end
  end

  describe '#delete_at' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'deletes the value on the day' do
        expect { homepage.pv.delete_at(date) }
          .to change { homepage.pv.at(date) }
          .from(11).to(0)
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'deletes the value on the day' do
        expect { homepage.pv.delete_at(time) }
          .to change { homepage.pv.at(time) }
          .from(11).to(0)
      end
    end
  end

  describe '#range' do
    context 'with date' do
      let(:start_date) { Date.new(2021, 4, 1) }
      let(:end_date) { Date.new(2021, 4, 2) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv.range(start_date, end_date)).to eq [10, 11]
      end
    end

    context 'with time' do
      let(:start_time) { Time.local(2021, 4, 1, 10, 20, 30) }
      let(:end_time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv.range(start_time, end_time)).to eq [10, 11]
      end
    end
  end

  describe '#at' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns a counter object counted the day' do
        expect(homepage.pv.at(date).value).to eq 11
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns a counter object counted the day' do
        expect(homepage.pv.at(time).value).to eq 11
      end
    end
  end
end
