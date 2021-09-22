# frozen_string_literal: true

RSpec.describe Redis::MonthlySet do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      monthly_set :monthly_active_users

      def id
        1
      end
    end
  end

  let(:homepage) { Homepage.new }

  before do
    stub_const 'Homepage', mock_class
    Timecop.travel(Time.local(2021, 4, 1))
    homepage.monthly_active_users.merge('user1', 'user2', 'user3')
    Timecop.travel(Time.local(2021, 5, 1))
    homepage.monthly_active_users.merge('user1', 'user2', 'user1', 'user4', 'user5')
    Timecop.travel(Time.local(2021, 6, 1))
    homepage.monthly_active_users.merge('user1', 'user1', 'user3', 'user1', 'user1')
  end

  context 'with global: true' do
    let(:mock_class) do
      Class.new do
        include Redis::Objects

        monthly_set :monthly_active_users, global: true
      end
    end

    let(:homepage) { Homepage }

    it 'supports class-level global sets of simple values' do
      expect(homepage.redis.scard('homepage::monthly_active_users:2021-04')).to eq 3
      expect(homepage.redis.scard('homepage::monthly_active_users:2021-05')).to eq 4
      expect(homepage.redis.scard('homepage::monthly_active_users:2021-06')).to eq 2
    end
  end

  describe 'timezone' do
    context 'when Time class is extended by Active Support' do
      it do
        allow(Time).to receive(:current).and_return(Time.now)
        homepage.monthly_active_users << 'user1'
        expect(Time).to have_received(:current).with(no_args)
      end
    end

    context 'when Time class is not extended by Active Support' do
      it do
        allow(Time).to receive(:now).and_return(Time.now)
        homepage.monthly_active_users << 'user1'
        expect(Time).to have_received(:now).with(no_args)
      end
    end
  end

  describe 'keys' do
    it 'appends new sets automatically with the current month' do
      expect(homepage.redis.scard('homepage:1:monthly_active_users:2021-04')).to eq 3
      expect(homepage.redis.scard('homepage:1:monthly_active_users:2021-05')).to eq 4
      expect(homepage.redis.scard('homepage:1:monthly_active_users:2021-06')).to eq 2
    end
  end

  describe '#members' do
    it 'returns members added this month' do
      expect(homepage.monthly_active_users.members).to contain_exactly('user1', 'user3')
    end
  end

  describe '#[]' do
    context 'with date' do
      let(:date) { Date.new(2021, 4, 1) }

      it 'returns the members added the month' do
        expect(homepage.monthly_active_users[date])
          .to contain_exactly('user1', 'user2', 'user3')
      end
    end

    context 'with date and length' do
      let(:date) { Date.new(2021, 5, 1) }

      it 'returns the members added within the duration' do
        expect(homepage.monthly_active_users[date, 2])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end

    context 'with range' do
      let(:range) do
        Date.new(2021, 4, 1)..Date.new(2021, 5, 1)
      end

      it 'returns the members counted within the duration' do
        expect(homepage.monthly_active_users[range])
          .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
      end
    end
  end

  describe '#delete_at' do
    it 'deletes the members on the month' do
      date = Date.new(2021, 5, 1)
      expect { homepage.monthly_active_users.delete_at(date) }
        .to change { homepage.monthly_active_users.at(date).length }
        .from(4).to(0)
    end
  end

  describe '#range' do
    let(:start_date) { Date.new(2021, 4, 1) }
    let(:end_date) { Date.new(2021, 5, 1) }

    it 'returns the members added within the duration' do
      expect(homepage.monthly_active_users.range(start_date, end_date))
        .to contain_exactly('user1', 'user2', 'user3', 'user4', 'user5')
    end
  end

  describe '#at' do
    let(:date) { Date.new(2021, 5, 1) }

    it 'returns the members added the month' do
      expect(homepage.monthly_active_users.at(date))
        .to contain_exactly('user1', 'user2', 'user4', 'user5')
    end
  end
end
