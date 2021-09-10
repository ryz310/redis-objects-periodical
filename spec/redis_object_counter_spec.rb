# frozen_string_literal: true

RSpec.describe RedisObjectCounter do
  it 'has a version number' do
    expect(RedisObjectCounter::VERSION).not_to be nil
  end
end
