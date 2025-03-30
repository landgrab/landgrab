# frozen_string_literal: true

module TilesHelper
  def render_w3w_code(tile)
    content_tag(:code, "///#{tile.w3w}")
  end

  def rounded_coordinates(point)
    [point.x, point.y].map { |c| format('%.6f', c) }.join(',')
  end
end
