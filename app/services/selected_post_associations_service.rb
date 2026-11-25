# frozen_string_literal: true

# Works out which postables the post form's association fields should show:
# the submitted values after a failed save, else the post's current
# associations, else the single postable preset by a "Create a post about this..." link.
class SelectedPostAssociationsService
  PRESETTABLE_TYPES = %w[Team Project Plot Tile].freeze

  class << self
    def call(post:, submitted: nil, preset_type: nil, preset_id: nil)
      if submitted.present?
        from_submitted(submitted)
      elsif post.persisted?
        from_post(post)
      else
        from_preset(preset_type, preset_id)
      end
    end

    private

    def empty
      { team_ids: [], project_ids: [], plot_ids: [], tile_w3w_list: '' }
    end

    def from_submitted(submitted)
      {
        team_ids: Array(submitted[:team_ids]),
        project_ids: Array(submitted[:project_ids]),
        plot_ids: Array(submitted[:plot_ids]),
        tile_w3w_list: submitted[:tile_w3w_list].to_s
      }
    end

    def from_post(post)
      {
        team_ids: post.associated_teams.map(&:hashid),
        project_ids: post.associated_projects.map(&:hashid),
        plot_ids: post.associated_plots.map(&:hashid),
        tile_w3w_list: post.associated_tiles.map(&:w3w).sort.join(', ')
      }
    end

    def from_preset(type, id)
      return empty unless PRESETTABLE_TYPES.include?(type) && id.present?

      postable = type.constantize.find_by_hashid(id)
      return empty if postable.nil?

      selected = empty
      if postable.is_a?(Tile)
        selected[:tile_w3w_list] = postable.w3w
      else
        selected[:"#{type.underscore}_ids"] = [postable.hashid]
      end
      selected
    end
  end
end
