# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :team, optional: true
  belongs_to :referrer, class_name: 'User', optional: true
  has_many :referees, class_name: 'User', foreign_key: 'referrer_id', inverse_of: :referrer, dependent: :nullify

  has_many :subscriptions_subscribed, class_name: 'Subscription', foreign_key: 'subscriber_id', inverse_of: :subscriber, dependent: :restrict_with_exception
  has_many :subscriptions_redeemed, class_name: 'Subscription', foreign_key: 'redeemer_id', inverse_of: :redeemer, dependent: :restrict_with_exception
  has_many :posts_authored, class_name: 'Post', foreign_key: 'author_id', inverse_of: :author, dependent: :restrict_with_exception
  has_many :post_views, class_name: 'PostView', inverse_of: :user, dependent: :destroy
  has_many :comments_authored, class_name: 'Comment', inverse_of: :author, dependent: :restrict_with_exception

  validates :first_name, :last_name, length: { maximum: 255 }
  validates :stripe_customer_id, allow_blank: true,
                                 format: { with: /\Acus_[0-9a-zA-Z]+\z/, message: 'must start with cus_' },
                                 uniqueness: true
  validates :username, allow_blank: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: 'can only contain letters, numbers, and underscores' }
  validates :website_url, allow_blank: true, url: true
  validates :website_title, length: { maximum: 255 }

  before_create :normalize_names
  before_create :generate_referral_token

  auto_strip_attributes :first_name, :last_name, :username, :website_url, :website_title, squish: true

  def website_link_title
    website_title.presence || 'Personal website'
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def display_name
    first_name || email.split('@').first
  end

  def subscription_for_project(project)
    subscriptions_for_project(project).first
  end

  def subscriptions_for_project(project)
    return [] if project.nil?

    associated_subscriptions
      .joins(:tile).includes(tile: :plot)
      .where(tiles: { plot_id: project.plots.ids })
      .order(id: :desc)
      .select(&:usable_stripe_status?)
  end

  def subscription_for_plot(plot)
    subscriptions_for_plot(plot).first
  end

  def subscriptions_for_plot(plot)
    return [] if plot.nil?

    associated_subscriptions
      .joins(:tile).includes(tile: :plot)
      .where(tiles: { plot_id: plot.id })
      .order(id: :desc)
      .select(&:usable_stripe_status?)
  end

  def associated_subscriptions
    Subscription.where(subscriber_id: id).or(Subscription.where(redeemer_id: id))
  end

  def linkable_subscriptions
    subscriptions_redeemed.stripe_status_active.where.missing(:tile)
  end

  def viewed_post_ids
    post_views&.distinct(:post_id)&.pluck(:post_id)
  end

  private

  def generate_referral_token
    loop do
      token = SecureRandom.base36(12)
      unless User.exists?(referral_token: token)
        self.referral_token = token
        break
      end
    end
  end

  def normalize_names
    # Normalize names that are all lowercase or all uppercase (e.g., 'john' or 'JOHN' -> 'John')
    # Don't touch names with mixed case (e.g., 'de Santos')
    self.first_name = first_name.capitalize if first_name == first_name.downcase || first_name == first_name.upcase
    self.last_name = last_name.capitalize if last_name == last_name.downcase || last_name == last_name.upcase
  end
end
