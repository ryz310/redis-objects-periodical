# frozen_string_literal: true

RSpec.describe Redis::MinutelySet do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      minutely_set :minutely_active_users, expiration: 86_400 # about a day

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1, 10, 20))
    homepage.minutely_active_users.merge('user1', 'user2', 'user3')
    Timecop.travel(Time.local(2021, 4, 1, 10, 21))
    homepage.minutely_active_users.merge('user1', 'user2', 'user1', 'user4', 'user5')
    Timecop.travel(Time.local(2021, 4, 1, 10, 22))
    homepage.minutely_active_users.merge('user1', 'user1', 'user3', 'user1', 'user1')
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        minutely_set :minutely_active_users, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level global sets of simple values' do
      expect(homepage.redis.scard('homepage::minutely_active_users:2021-04-01T10:20')).to eq 3
      expect(homepage.redis.scard('homepage::minutely_active_users:2021-04-01T10:21')).to eq 4
      expect(homepage.redis.scard('homepage::minutely_active_users:2021-04-01T10:22')).to eq 2
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.minutely_active_users << 'user1'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.minutely_active_users << 'user1'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new sets automatically with the current minute' do
      expect(homepage.redis.scard('homepage:1:minutely_active_users:2021-04-01T10:20')).to eq 3
      expect(homepage.redis.scard('homepage:1:minutely_active_users:2021-04-01T10:21')).to eq 4
      expect(homepage.redis.scard('homepage:1:minutely_active_users:2021-04-01T10:22')).to eq 2
    end
  end

  describe '#members' do
    it 'returns members added this minute' do
      expect(homepage.minutely_active_users.members).to contain_exactly('user1', 'user3')
    end
  end

  describe '#[]' do
    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20) }

      it 'returns the members added the minute' do
        expect(homepage.minutely_active_users[time])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns the members added within the duration' do
        expect(homepage.minutely_active_users[time, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2021, 4, 1, 10, 21) }

      it 'returns an empty array' do
        expect(homepage.minutely_active_users[time, 0]).to eq []
      end
    end

    context 'with range' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20)..Time.local(2021, 4, 1, 10, 21)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.minutely_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#delete_at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'deletes the members on the minute' do
      expect { homepage.minutely_active_users.delete_at(time) }
        .to change { homepage.minutely_active_users.at(time).length }
        .from(4).to(0)
    end
  end

  describe '#range' do
    let(:start_time) { Time.local(2021, 4, 1, 10, 20) }
    let(:end_time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns the members added within the duration' do
      expect(homepage.minutely_active_users.range(start_time, end_time))
        .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
    end
  end

  describe '#at' do
    let(:time) { Time.local(2021, 4, 1, 10, 21) }

    it 'returns a set object added the minute' do
      expect(homepage.minutely_active_users.at(time).members)
        .to contain_exactly('user1', 'user2', 'user4', 'user5')
      expect(homepage.minutely_active_users.at(time).length)
        .to eq 4
    end
  end
end
