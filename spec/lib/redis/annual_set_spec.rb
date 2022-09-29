# frozen_string_literal: true

RSpec.describe Redis::AnnualSet do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      annual_set :annual_active_users

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1))
    homepage.annual_active_users.merge('user1', 'user2', 'user3')
    Timecop.travel(Time.local(2022, 4, 1))
    homepage.annual_active_users.merge('user1', 'user2', 'user1', 'user4', 'user5')
    Timecop.travel(Time.local(2023, 4, 1))
    homepage.annual_active_users.merge('user1', 'user1', 'user3', 'user1', 'user1')
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        annual_set :annual_active_users, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level global sets of simple values' do
      expect(homepage.redis.scard('homepage::annual_active_users:2021')).to eq 3
      expect(homepage.redis.scard('homepage::annual_active_users:2022')).to eq 4
      expect(homepage.redis.scard('homepage::annual_active_users:2023')).to eq 2
    end
  end

  describe 'timezone' do
    before { Timecop.travel(Time.local(2024, 4, 1)) }

    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.annual_active_users << 'user1'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.annual_active_users << 'user1'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new sets automatically with the current year' do
      expect(homepage.redis.scard('homepage:1:annual_active_users:2021')).to eq 3
      expect(homepage.redis.scard('homepage:1:annual_active_users:2022')).to eq 4
      expect(homepage.redis.scard('homepage:1:annual_active_users:2023')).to eq 2
    end
  end

  describe '#members' do
    it 'returns members added this year' do
      expect(homepage.annual_active_users.members).to contain_exactly('user1', 'user3')
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the members added the year' do
        expect(homepage.annual_active_users[date])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns the members added within the duration' do
        expect(homepage.annual_active_users[date, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with date and length (zero)' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns an empty array' do
        expect(homepage.annual_active_users[date, 0]).to eq []
      end
    end

    context 'with range of date' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2022, 4, 1)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.annual_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time' do
      let(:time) { Time.local(2021, 4, 1, 10, 20, 30) }

      it 'returns the members added the year' do
        expect(homepage.annual_active_users[time])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with time and length' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns the members added within the duration' do
        expect(homepage.annual_active_users[time, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time and length (zero)' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns an empty array' do
        expect(homepage.annual_active_users[time, 0]).to eq []
      end
    end

    context 'with range of time' do
      let(:range) do
        Time.local(2021, 4, 1, 10, 20, 30)..Time.local(2022, 4, 1, 10, 20, 30)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.annual_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#delete_at' do
    context 'with date' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'deletes the members on the year' do
        expect { homepage.annual_active_users.delete_at(date) }
          .to change { homepage.annual_active_users.at(date).length }
          .from(4).to(0)
      end
    end

    context 'with time' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'deletes the members on the year' do
        expect { homepage.annual_active_users.delete_at(time) }
          .to change { homepage.annual_active_users.at(time).length }
          .from(4).to(0)
      end
    end
  end

  describe '#range' do
    context 'with date' do
      let(:start_date) { Date.new(2021, 4, 1) }
      let(:end_date) { Date.new(2022, 4, 1) }

      it 'returns the members added within the duration' do
        expect(homepage.annual_active_users.range(start_date, end_date))
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with time' do
      let(:start_time) { Time.local(2021, 4, 1, 10, 20, 30) }
      let(:end_time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns the members added within the duration' do
        expect(homepage.annual_active_users.range(start_time, end_time))
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#at' do
    context 'with date' do
      let(:date) { Date.new(2022, 4, 1) }

      it 'returns a set object added the year' do
        expect(homepage.annual_active_users.at(date).members)
          .to contain_exactly('user1', 'user2', 'user4', 'user5')
        expect(homepage.annual_active_users.at(date).length)
          .to eq 4
      end
    end

    context 'with time' do
      let(:time) { Time.local(2022, 4, 1, 10, 20, 30) }

      it 'returns a set object added the year' do
        expect(homepage.annual_active_users.at(time).members)
          .to contain_exactly('user1', 'user2', 'user4', 'user5')
        expect(homepage.annual_active_users.at(time).length)
          .to eq 4
      end
    end
  end
end
