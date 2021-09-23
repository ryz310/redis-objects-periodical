# frozen_string_literal: true

RSpec.describe Redis::AnnualCounter do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      annual_counter :pv

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
    Timecop.travel(Time.local(2022, 4, 1))
    homepage.pv.increment(11)
    Timecop.travel(Time.local(2023, 4, 1))
    homepage.pv.increment(12)
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        annual_counter :pv, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level increment/decrement of global counters' do
      expect(homepage.redis.get('homepage::pv:2021').to_i).to eq 10
      expect(homepage.redis.get('homepage::pv:2022').to_i).to eq 11
      expect(homepage.redis.get('homepage::pv:2023').to_i).to eq 12
    end
  end

  describe 'timezone' do
    before { Timecop.travel(Time.local(2024, 4, 1)) }

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
    it 'appends new counters automatically with the current year' do
      expect(homepage.redis.get('homepage:1:pv:2021').to_i).to eq 10
      expect(homepage.redis.get('homepage:1:pv:2022').to_i).to eq 11
      expect(homepage.redis.get('homepage:1:pv:2023').to_i).to eq 12
    end
  end

  describe '#value' do
    it 'returns the value counted this year' do
      expect(homepage.pv.value).to eq 12
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the value counted the year' do
        expect(homepage.pv[date]).to eq 10
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns the values counted within the duration' do
        expect(homepage.pv[date, 2]).to eq [11, 12]
      end
    end

    context 'with range' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2022, 4, 1)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.pv[range]).to eq [10, 11]
      end
    end
  end

  describe '#delete_at' do
    it 'deletes the value on the year' do
      date = Date.new(2022, 4, 1)
      expect { homepage.pv.delete_at(date) }
        .to change { homepage.pv.at(date) }
        .from(11).to(0)
    end
  end

  describe '#range' do
    let(:start_date) { Date.new(2021, 4, 1) }
    let(:end_date) { Date.new(2022, 4, 1) }

    it 'returns the values counted within the duration' do
      expect(homepage.pv.range(start_date, end_date)).to eq [10, 11]
    end
  end

  describe '#at' do
    let(:date) { Date.new(2022, 4, 1) }

    it 'returns a counter object counted the year' do
      expect(homepage.pv.at(date).value).to eq 11
    end
  end
end
