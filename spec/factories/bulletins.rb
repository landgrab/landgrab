# frozen_string_literal: true

FactoryBot.define do
  factory :bulletin do
    subject { 'Spring news' }
    author factory: %i[user]

    # Posts default to one that a single subscriber can view, so the bulletin is valid
    posts { [create(:post, :viewed_by_subscriber)] }
  end
end
