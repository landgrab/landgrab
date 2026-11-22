# frozen_string_literal: true

# Works out how a tile relates to the person viewing a map (the viewer) and a
# team. Only tiles whose latest subscription is usable are highlighted.
class TeamTileHighlightService
  attr_reader :viewer, :team

  def initialize(viewer:, team:)
    @viewer = viewer
    @team = team
  end

  def category_for(tile)
    subscription = tile.latest_subscription
    return unless subscription&.usable_stripe_status?
    return :mine if viewer.present? && subscription.redeemer_id == viewer.id

    :team if member_ids.include?(subscription.redeemer_id)
  end

  # Every tile that would be highlighted, optionally limited to one plot.
  def highlighted_tiles(plot: nil)
    scope = team.team_tiles
    scope = scope.or(Tile.joins(:latest_subscription).merge(Subscription.usable).where(subscriptions: { redeemer_id: viewer.id })) if viewer.present?
    plot.present? ? scope.where(plot:) : scope
  end

  def label(category, count)
    tiles_word = 'tile'.pluralize(count)

    case category
    when :mine then "My #{tiles_word}"
    when :team then "#{team.title} #{tiles_word}"
    end
  end

  private

  def member_ids
    @member_ids ||= team.users.pluck(:id).to_set
  end
end
