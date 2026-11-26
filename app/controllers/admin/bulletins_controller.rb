# frozen_string_literal: true

module Admin
  class BulletinsController < ApplicationController
    before_action :check_admin
    before_action :set_bulletin, only: %i[show edit update destroy preview send_test confirm]
    before_action :require_draft, only: %i[edit update destroy confirm]
    before_action :require_simple_content, only: %i[preview send_test]

    def index
      @bulletins = Bulletin.includes(:author, :posts).order(id: :desc).page(params[:page])
      @delivery_counts = delivery_counts(@bulletins)
    end

    def show
      @deliveries = @bulletin.deliveries.includes(:user).order(:id).page(params[:page]) if @bulletin.confirmed?
    end

    def new
      @bulletin = Bulletin.new
    end

    def edit; end

    def create
      @bulletin = Bulletin.new(bulletin_params)
      @bulletin.author = current_user
      @bulletin.posts = selected_posts

      if @bulletin.save
        redirect_to admin_bulletin_path(@bulletin), notice: 'Bulletin was successfully created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if save_with_posts
        redirect_to admin_bulletin_path(@bulletin), notice: 'Bulletin was successfully updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @bulletin.destroy!
      redirect_to admin_bulletins_path, notice: 'Draft bulletin was deleted.'
    end

    # Shows the email exactly as the current admin would receive it
    def preview
      message = BulletinMailer.with(bulletin: @bulletin, user: current_user).bulletin.message
      render html: (message.html_part || message).body.decoded.html_safe, layout: false # rubocop:disable Rails/OutputSafety
    end

    # Emails the current admin a copy. Not recorded as a delivery.
    def send_test
      BulletinMailer.with(bulletin: @bulletin, user: current_user).bulletin.deliver_later
      redirect_to admin_bulletin_path(@bulletin), notice: "A test email is on its way to #{current_user.email}."
    end

    def confirm
      if BulletinConfirmationService.call(@bulletin)
        redirect_to admin_bulletin_path(@bulletin),
                    notice: "Bulletin confirmed. #{helpers.pluralize(@bulletin.deliveries.count, 'email')} queued for sending."
      else
        redirect_to admin_bulletin_path(@bulletin),
                    flash: { error: "Not confirmed: #{@bulletin.errors.full_messages.to_sentence}" }
      end
    end

    helper_method :selectable_posts

    private

    def set_bulletin
      @bulletin = Bulletin.find_by_hashid!(params[:id])
    end

    def require_draft
      return unless @bulletin.confirmed?

      redirect_to admin_bulletin_path(@bulletin), flash: { error: 'A confirmed bulletin cannot be changed.' }
    end

    def require_simple_content
      problems = @bulletin.content_problems
      return if problems.empty?

      redirect_to admin_bulletin_path(@bulletin), flash: { error: problems.join(' ') }
    end

    # Posts are swapped in the same transaction as the other fields, so an invalid bulletin changes nothing
    def save_with_posts
      saved = false
      Bulletin.transaction do
        @bulletin.assign_attributes(bulletin_params)
        @bulletin.posts = selected_posts
        saved = @bulletin.save
        raise ActiveRecord::Rollback unless saved
      end
      saved
    end

    def selected_posts
      Array(params.dig(:bulletin, :post_ids)).compact_blank.filter_map { |hashid| Post.find_by_hashid(hashid) }
    end

    # The most recent posts, plus any already chosen, for the form's post picker
    def selectable_posts
      (Post.order(id: :desc).limit(200).to_a + @bulletin.posts.to_a).uniq
    end

    def delivery_counts(bulletins)
      counts = BulletinDelivery.where(bulletin: bulletins).group(:bulletin_id)
                               .pluck(:bulletin_id, Arel.sql('count(sent_at)'), Arel.sql('count(failed_at)'))
      counts.to_h { |bulletin_id, sent, failed| [bulletin_id, { sent:, failed: }] }
    end

    def bulletin_params
      params.expect(bulletin: %i[subject intro])
    end
  end
end
