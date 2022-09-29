# frozen_string_literal: true

RSpec.describe Redis::DailySet do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      daily_set :daily_active_users, expiration: 2_678_400 # about a month

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1))
    homepage.daily_active_users.merge('user1', 'user2', 'user3')
    Timecop.travel(Time.local(2021, 4, 2))
    homepage.daily_active_users.merge('user1', 'user2', 'user1', 'user4', 'user5')
    Timecop.travel(Time.local(2021, 4, 3))
    homepage.daily_active_users.merge('user1', 'user1', 'user3', 'user1', 'user1')
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        daily_set :daily_active_users, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level global sets of simple values' do
      expect(homepage.redis.scard('homepage::daily_active_users:2021-04-01')).to eq 3
      expect(homepage.redis.scard('homepage::daily_active_users:2021-04-02')).to eq 4
      expect(homepage.redis.scard('homepage::daily_active_users:2021-04-03')).to eq 2
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.daily_active_users << 'user1'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.daily_active_users << 'user1'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new sets automatically with the current date' do
      expect(homepage.redis.scard('homepage:1:daily_active_users:2021-04-01')).to eq 3
      expect(homepage.redis.scard('homepage:1:daily_active_users:2021-04-02')).to eq 4
      expect(homepage.redis.scard('homepage:1:daily_active_users:2021-04-03')).to eq 2
    end
  end

  describe '#members' do
    it 'returns members added today' do
      expect(homepage.daily_active_users.members).to contain_exactly('user1', 'user3')
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the members added the day' do
        expect(homepage.daily_active_users[date])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns the members added within the duration' do
        expect(homepage.daily_active_users[date, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with range of date' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2021, 4, 2)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.daily_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20, 30) }

      it 'returns the members added the day' do
        expect(homepage.daily_active_users[time])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns the members added within the duration' do
        expect(homepage.daily_active_users[time, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with range of time' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20, 30)..Time.local(2021, 4, 2, 10, 20, 30)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.daily_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#delete_at' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'deletes the members on the day' do
        expect { homepage.daily_active_users.delete_at(date) }
          .to change { homepage.daily_active_users.at(date).length }
          .from(4).to(0)
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'deletes the members on the day' do
        expect { homepage.daily_active_users.delete_at(time) }
          .to change { homepage.daily_active_users.at(time).length }
          .from(4).to(0)
      end
    end
  end

  describe '#range' do
    context 'with date' do
      let(:start_date) { Date.new(2021, 4, 1) }
      let(:end_date) { Date.new(2021, 4, 2) }

      it 'returns the members added within the duration' do
        expect(homepage.daily_active_users.range(start_date, end_date))
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time' do
      let(:start_time) { Time.local(2021, 4, 1, 10, 20, 30) }
      let(:end_time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns the members added within the duration' do
        expect(homepage.daily_active_users.range(start_time, end_time))
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#at' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 2) }

      it 'returns a set object added the day' do
        expect(homepage.daily_active_users.at(date).members)
          .to contain_exactly('user1', 'user2', 'user4', 'user5')
        expect(homepage.daily_active_users.at(date).length)
          .to eq 4
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 2, 10, 20, 30) }

      it 'returns a set object added the day' do
        expect(homepage.daily_active_users.at(time).members)
          .to contain_exactly('user1', 'user2', 'user4', 'user5')
        expect(homepage.daily_active_users.at(time).length)
          .to eq 4
      end
    end
  end
end
