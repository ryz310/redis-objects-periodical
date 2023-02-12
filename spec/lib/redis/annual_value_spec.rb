# frozen_string_literal: true

RSpec.describe Redis::AnnualValue do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      annual_value :cache

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1))
    homepage.cache.value = 'a'
    Timecop.travel(Time.local(2022, 4, 1))
    homepage.cache.value = 'b'
    Timecop.travel(Time.local(2023, 4, 1))
    homepage.cache.value = 'c'
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        annual_value :cache, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level value of global values' do
      expect(homepage.redis.get('homepage::cache:2021')).to eq 'a'
      expect(homepage.redis.get('homepage::cache:2022')).to eq 'b'
      expect(homepage.redis.get('homepage::cache:2023')).to eq 'c'
    end
  end

  describe 'timezone' do
    before { Timecop.travel(Time.local(2024, 4, 1)) }

    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.cache = 'd'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.cache = 'd'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new values automatically with the current year' do
      expect(homepage.redis.get('homepage:1:cache:2021')).to eq 'a'
      expect(homepage.redis.get('homepage:1:cache:2022')).to eq 'b'
      expect(homepage.redis.get('homepage:1:cache:2023')).to eq 'c'
    end
  end

  describe '#value' do
    it 'returns the value counted this year' do
      expect(homepage.cache.value).to eq 'c'
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the value counted the year' do
        expect(homepage.cache[date]).to eq 'a'
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns the values counted within the duration' do
        expect(homepage.cache[date, 2]).to eq %w[b c]
      end
    end

    context 'with date and length (zero)' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns an empty array' do
        expect(homepage.cache[date, 0]).to eq []
      end
    end

    context 'with range of date' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2022, 4, 1)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.cache[range]).to eq %w[a b]
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20, 30) }

      it 'returns the value counted the year' do
        expect(homepage.cache[time]).to eq 'a'
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns the values counted within the duration' do
        expect(homepage.cache[time, 2]).to eq %w[b c]
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns an empty array' do
        expect(homepage.cache[time, 0]).to eq []
      end
    end

    context 'with range of time' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20, 30)..Time.local(2022, 4, 1, 10, 20, 30)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.cache[range]).to eq %w[a b]
      end
    end
  end

  describe '#delete_at' do
    context 'with date' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'deletes the value on the year' do
        expect { homepage.cache.delete_at(date) }
          .to change { homepage.cache.at(date).value }
          .from('b').to(nil)
      end
    end

    context 'with time' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'deletes the value on the year' do
        expect { homepage.cache.delete_at(time) }
          .to change { homepage.cache.at(time).value }
          .from('b').to(nil)
      end
    end
  end

  describe '#range' do
    context 'with date' do
      let(:start_date) { Date.new(2021, 4, 1) }
      let(:end_date) { Date.new(2022, 4, 1) }

      it 'returns the values counted within the duration' do
        expect(homepage.cache.range(start_date, end_date)).to eq %w[a b]
      end
    end

    context 'with time' do
      let(:start_time) { Time.local(2021, 4, 1, 10, 20, 30) }
      let(:end_time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns the values counted within the duration' do
        expect(homepage.cache.range(start_time, end_time)).to eq %w[a b]
      end
    end
  end

  describe '#at' do
    context 'with date' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns a value object counted the year' do
        expect(homepage.cache.at(date).value).to eq 'b'
      end
    end

    context 'with time' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns a value object counted the year' do
        expect(homepage.cache.at(time).value).to eq 'b'
      end
    end
  end
end
