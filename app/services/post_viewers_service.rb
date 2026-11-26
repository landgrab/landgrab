# frozen_string_literal: true

# The users who can view a post: the set-based equivalent of Post#viewable_by?, so a whole
# audience can be found with a few queries instead of checking each user in turn. It follows the
# same rules as the viewable_by? methods on each kind of postable:
#
# - a tile's subscriber or redeemer
# - the subscriber (not the redeemer) of a tile in an associated plot or project
# - any member of an associated team
class PostViewersService
  class << self
    def call(post)
      new(post).viewers
    end
  end

  def initialize(post)
    @post = post
  end

  # A User relation
  def viewers
    [
      users_via_tiles(associated_tiles, redeemers: true),
      users_via_tiles(tiles_in_plots, redeemers: false),
      users_via_tiles(tiles_in_projects, redeemers: false),
      User.where(team_id: postable_ids(Team))
    ].reduce(:or)
  end

  private

  attr_reader :post

  def postable_ids(klass)
    post.post_associations.where(postable_type: klass.name).select(:postable_id)
  end

  def associated_tiles
    Tile.where(id: postable_ids(Tile))
  end

  def tiles_in_plots
    Tile.where(plot_id: postable_ids(Plot))
  end

  def tiles_in_projects
    Tile.where(plot_id: Plot.where(project_id: postable_ids(Project)).select(:id))
  end

  # Users holding the latest subscription of the given tiles, as subscriber and optionally redeemer
  def users_via_tiles(tiles, redeemers:)
    subscriptions = Subscription.where(id: tiles.reorder(nil).select(:latest_subscription_id))

    users = User.where(id: subscriptions.select(:subscriber_id))
    users = users.or(User.where(id: subscriptions.select(:redeemer_id))) if redeemers
    users
  end
end
