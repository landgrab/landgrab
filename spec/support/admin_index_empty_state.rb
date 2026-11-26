# frozen_string_literal: true

# For an admin controller spec with render_views and a signed-in admin: an empty index says so exactly once
RSpec.shared_examples 'an admin index with a single empty state' do |message|
  it 'says there are none once' do
    get(:index)

    expect(response.body.scan(message).size).to eq 1
  end
end
