# frozen_string_literal: true

RSpec.describe Redis::MinutelyHashKey do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      minutely_hash_key :browsing_history

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1, 10, 20))
    homepage.browsing_history.bulk_set('item1' => 1.5, 'item2' => 2)
    Timecop.travel(Time.local(2021, 4, 1, 10, 21))
    homepage.browsing_history.bulk_set('item1' => 3, 'item2' => 'a', 'item3' => 5)
    Timecop.travel(Time.local(2021, 4, 1, 10, 22))
    homepage.browsing_history.bulk_set('item2' => 1, 'item3' => 2, 'item4' => 1)
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        minutely_hash_key :browsing_history, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level increment/decrement of global counters' do
      expect(homepage.redis.hgetall('homepage::browsing_history:2021-04-01T10:20'))
        .to eq({ 'item1' => '1.5', 'item2' => '2' })
      expect(homepage.redis.hgetall('homepage::browsing_history:2021-04-01T10:21'))
        .to eq({ 'item1' => '3', 'item2' => 'a', 'item3' => '5' })
      expect(homepage.redis.hgetall('homepage::browsing_history:2021-04-01T10:22'))
        .to eq({ 'item2' => '1', 'item3' => '2', 'item4' => '1' })
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.browsing_history.incr('item0')
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.browsing_history.incr('item0')
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new counters automatically with the current year' do
      expect(homepage.redis.hgetall('homepage:1:browsing_history:2021-04-01T10:20'))
        .to eq({ 'item1' => '1.5', 'item2' => '2' })
      expect(homepage.redis.hgetall('homepage:1:browsing_history:2021-04-01T10:21'))
        .to eq({ 'item1' => '3', 'item2' => 'a', 'item3' => '5' })
      expect(homepage.redis.hgetall('homepage:1:browsing_history:2021-04-01T10:22'))
        .to eq({ 'item2' => '1', 'item3' => '2', 'item4' => '1' })
    end
  end

  describe '#all' do
    it 'returns the fields counted this year' do
      expect(homepage.browsing_history.all)
        .to eq({ 'item2' => '1', 'item3' => '2', 'item4' => '1' })
    end
  end

  describe '#[]' do
    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20) }

      it 'returns the field counted the year' do
        expect(homepage.browsing_history[time]).to eq({ 'item1' => '1.5', 'item2' => '2' })
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns the fields counted within the duration' do
        expect(homepage.browsing_history[time, 2])
          .to eq({ 'item1' => '3', 'item2' => 'a,1', 'item3' => '7', 'item4' => '1' })
      end
    end

    context 'with range' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20)..Time.local(2021, 4, 1, 10, 21)
      end

      it 'returns the values counted within the duration' do
        expect(homepage.browsing_history[range])
          .to eq({ 'item1' => '4.5', 'item2' => '2,a', 'item3' => '5' })
      end
    end
  end

  describe '#delete_at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'deletes the hash on the year' do
      expect { homepage.browsing_history.delete_at(time) }
        .to change { homepage.browsing_history.at(time) }
        .from({ 'item1' => '3', 'item2' => 'a', 'item3' => '5' }).to({})
    end
  end

  describe '#range' do
    let(:start_time) { Time.local(2021, 4, 1, 10, 20) }
    let(:end_time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns the hash counted within the duration' do
      expect(homepage.browsing_history.range(start_time, end_time))
        .to eq({ 'item1' => '4.5', 'item2' => '2,a', 'item3' => '5' })
    end
  end

  describe '#at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns a counter object counted the year' do
      expect(homepage.browsing_history.at(time).all)
        .to eq({ 'item1' => '3', 'item2' => 'a', 'item3' => '5' })
    end
  end
end
