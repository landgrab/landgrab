# frozen_string_literal: true

# The users who can view a post: the set-based equivalent of Post#viewable_by?, so a whole
# audience can be found with a few queries instead of checking each user in turn. The
# subscription rule is defined once, in Subscription (see Subscription.viewers and #viewable_by?):
#
# - the subscriber or redeemer of a usable subscription on a tile that is associated, or in an
#   associated plot or project
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
    Subscription.where(id: tiles.select(:latest_subscription_id)).viewers
                .or(User.where(team_id: postable_ids(Team)))
  end

  private

  attr_reader :post

  def postable_ids(klass)
    post.post_associations.where(postable_type: klass.name).select(:postable_id)
  end

  def tiles
    Tile.where(id: postable_ids(Tile))
        .or(Tile.where(plot_id: postable_ids(Plot)))
        .or(Tile.where(plot_id: Plot.where(project_id: postable_ids(Project)).select(:id)))
        .reorder(nil)
  end
end
