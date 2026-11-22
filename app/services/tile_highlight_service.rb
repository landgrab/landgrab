# frozen_string_literal: true

# Works out how a tile relates to the person viewing a map (the viewer) and the
# person the map is about (the subject, who is the viewer unless a profile says
# otherwise). Only tiles whose latest subscription is usable are highlighted.
class TileHighlightService
  # Highest priority first: a tile fitting several categories takes the first.
  CATEGORIES = %i[mine redeemed gifted referred].freeze

  attr_reader :viewer, :subject

  def initialize(viewer:, subject: viewer)
    @viewer = viewer
    @subject = subject
  end

  def subject_is_viewer?
    subject.present? && subject == viewer
  end

  def category_for(tile)
    subscription = tile.latest_subscription
    return unless subscription&.usable_stripe_status?
    return :mine if viewer.present? && subscription.redeemer_id == viewer.id

    subject_category(subscription) if subject.present?
  end

  # Every tile that would be highlighted, optionally limited to one plot.
  def highlighted_tiles(plot: nil)
    return Tile.none if viewer.nil? && subject.nil?

    scope = Tile.joins(:latest_subscription).merge(Subscription.usable)
    scope = scope.where(plot:) if plot.present?

    redeemer_ids = [viewer&.id, subject&.id].compact.uniq
    highlighted = scope.where(subscriptions: { redeemer_id: redeemer_ids })
    return highlighted if subject.nil?

    highlighted
      .or(scope.where(subscriptions: { subscriber_id: subject.id }))
      .or(scope.where(subscriptions: { subscriber_id: subject.referees.select(:id) }))
  end

  private

  def subject_category(subscription)
    return :redeemed if subscription.redeemer_id == subject.id
    return :gifted if subscription.subscriber_id == subject.id

    :referred if referee_ids.include?(subscription.subscriber_id)
  end

  def referee_ids
    @referee_ids ||= subject.referees.pluck(:id).to_set
  end
end
