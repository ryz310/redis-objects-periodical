# frozen_string_literal: true

RSpec.describe Redis::Objects do
  let(:mock_class) do
    Class.new do
      include Redis::Objects

      counter :my_posts

      def id
        1
      end
    end
  end

  it 'can use Redis::Objects' do
    instance = mock_class.new
    instance.my_posts.increment
    instance.my_posts.increment
    instance.my_posts.increment
    expect(instance.my_posts.value).to eq 3
  end
end
