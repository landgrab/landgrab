# frozen_string_literal: true

module TilesHelper
  def render_w3w_code(tile)
    content_tag(:code, "///#{tile.w3w}")
  end
end
