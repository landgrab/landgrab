# frozen_string_literal: true

# Makes a post's associations match the postables given, per type. A type is
# left untouched when its argument is nil, so partial updates never wipe it.
# Unknown identifiers are ignored.
class PostAssociationSyncService
  class << self
    def call(post, team_ids: nil, project_ids: nil, plot_ids: nil, tile_w3w_list: nil)
      sync(post, Team, find_by_hashids(Team, team_ids)) unless team_ids.nil?
      sync(post, Project, find_by_hashids(Project, project_ids)) unless project_ids.nil?
      sync(post, Plot, find_by_hashids(Plot, plot_ids)) unless plot_ids.nil?
      sync(post, Tile, tiles_for(tile_w3w_list)) unless tile_w3w_list.nil?
    end

    private

    def find_by_hashids(klass, hashids)
      Array(hashids).compact_blank.filter_map { |hashid| klass.find_by_hashid(hashid) }
    end

    def tiles_for(w3w_list)
      Tile.where(w3w: w3w_list.split(',').map(&:squish).compact_blank.map { |w3w| w3w.delete_prefix('///') })
    end

    def sync(post, klass, postables)
      wanted_ids = postables.map(&:id)
      existing = post.post_associations.where(postable_type: klass.name)

      existing.where.not(postable_id: wanted_ids).destroy_all
      (wanted_ids - existing.pluck(:postable_id)).each do |postable_id|
        post.post_associations.create!(postable_type: klass.name, postable_id: postable_id)
      end
    end
  end
end
