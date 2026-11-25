# frozen_string_literal: true

module AdminHelper
  def admin_title(resource_or_model, prefix: nil, suffix: nil)
    cls = case resource_or_model
          when String
            resource_or_model
          when Class
            x = resource_or_model.model_name.human.titleize
            suffix.present? ? x : x.pluralize
          else
            hashid = resource_or_model.hashid
            resource_or_model.model_name.human.titleize
          end
    title "🕵 #{prefix} #{cls} #{hashid} #{suffix}".squish

    capture do
      concat "🕵 #{cls} #{suffix}"
      if hashid
        concat ' - '
        concat render_id(resource_or_model)
      end
    end
  end

  # Header row with the page title on the left and any actions (e.g. New/Edit buttons) on the right.
  def admin_page_header(title, &block)
    tag.div(class: 'd-flex justify-content-between align-items-center flex-wrap gap-2 mb-3') do
      concat tag.h1(title, class: 'mb-0')
      concat tag.div(capture(&block), class: 'd-flex gap-2') if block
    end
  end

  # Button-styled link to the new form for a model, e.g. admin_new_button(Post) => "New Post".
  def admin_new_button(model, label: nil, params: {}, small: false)
    label ||= "New #{model.model_name.human.titleize}"
    link_to label, new_polymorphic_path([:admin, model], params), class: admin_button_classes('btn-primary', small:)
  end

  # Button-styled link to the edit form for a record, e.g. admin_edit_button(@post) => "Edit Post".
  def admin_edit_button(record, small: false)
    link_to "Edit #{record.model_name.human.titleize}", edit_polymorphic_path([:admin, record]),
            class: admin_button_classes('btn-secondary', small:)
  end

  def render_id(obj)
    tag.code(obj.hashid, style: 'text-transform: none;')
  end

  private

  def admin_button_classes(variant, small:)
    ['btn', variant, ('btn-sm' if small)].compact.join(' ')
  end
end
