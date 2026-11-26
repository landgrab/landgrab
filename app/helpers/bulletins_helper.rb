# frozen_string_literal: true

module BulletinsHelper
  STATUS_BADGES = { draft: 'bg-secondary', sending: 'bg-warning text-dark', sent: 'bg-success' }.freeze

  def render_bulletin_status(bulletin)
    status = bulletin.status
    tag.span(status.to_s.upcase, class: "badge #{STATUS_BADGES.fetch(status)}")
  end

  def render_delivery_status(delivery)
    if delivery.sent? then tag.span('SENT', class: 'badge bg-success')
    elsif delivery.failed? then tag.span('FAILED', class: 'badge bg-danger')
    else tag.span('PENDING', class: 'badge bg-warning text-dark')
    end
  end
end
