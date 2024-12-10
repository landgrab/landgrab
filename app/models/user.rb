# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :team, optional: true

  has_many :subscriptions_subscribed, class_name: 'Subscription', foreign_key: 'subscriber_id', inverse_of: :subscriber, dependent: :restrict_with_exception
  has_many :subscriptions_redeemed, class_name: 'Subscription', foreign_key: 'redeemer_id', inverse_of: :redeemer, dependent: :restrict_with_exception
  has_many :posts_authored, class_name: 'Post', foreign_key: 'author_id', inverse_of: :author, dependent: :restrict_with_exception
  has_many :post_views, class_name: 'PostView', inverse_of: :user, dependent: :destroy
  has_many :comments_authored, class_name: 'Comment', inverse_of: :author, dependent: :restrict_with_exception

  validates :first_name, :last_name, length: { maximum: 255 }
  validates :stripe_customer_id, allow_blank: true,
                                 format: { with: /\Acus_[0-9a-zA-Z]+\z/ },
                                 uniqueness: true

  before_create :titleize_lowercased_names

  def full_name
    [first_name, last_name].join(' ')
  end

  def display_name
    first_name || email.split('@').first
  end

  def subscription_for_plot(plot)
    subscriptions_subscribed
      .joins(:tile)
      .where(tiles: { plot_id: plot.id })
      .order(id: :desc)
      .first # assume latest is most likely to be active
  end

  def associated_subscriptions
    Subscription.where(subscriber_id: id).or(Subscription.where(redeemer_id: id))
  end

  def linkable_subscriptions
    subscriptions_redeemed.stripe_status_active.where.missing(:tile)
  end

  private

  def titleize_lowercased_names
    # Replace each name's first letter (unless it already has a capital, as in 'de Santos')
    self.first_name = first_name.sub(/\S/) { |s| s.mb_chars.upcase.to_s } if first_name == first_name.downcase
    self.last_name = last_name.sub(/\S/) { |s| s.mb_chars.upcase.to_s } if last_name == last_name.downcase
  end
end
