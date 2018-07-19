module Budgets
  class InvestmentsController < ApplicationController
    include FeatureFlags
    include CommentableActions
    include FlagActions

    before_action :authenticate_user!, except: [:index, :show, :redirect_to_new_url, :json_data]
    before_action :load_budget, except: [:redirect_to_new_url, :json_data]
    before_action :load_investment, only: [:show]

    load_and_authorize_resource :budget, except: [:redirect_to_new_url, :json_data]
    load_and_authorize_resource :investment, through: :budget, class: "Budget::Investment", except: [:redirect_to_new_url, :json_data]
    skip_authorization_check only: [:redirect_to_new_url, :json_data]

    before_action -> { flash.now[:notice] = flash[:notice].html_safe if flash[:html_safe] && flash[:notice] }
    before_action :load_ballot, only: [:index, :show]
    before_action :load_heading, only: [:index, :show]
    before_action :set_random_seed, only: :index
    before_action :load_categories, only: [:index, :new, :create]
    before_action :set_default_budget_filter, only: :index
    before_action :set_view, only: :index

    skip_authorization_check only: :json_data

    feature_flag :budgets

    has_orders %w{most_voted newest oldest}, only: :show
    has_orders ->(c) { c.instance_variable_get(:@budget).investments_orders }, only: :index
    has_filters %w{not_unfeasible feasible unfeasible unselected selected}, only: [:index, :show, :suggest]

    invisible_captcha only: [:create, :update], honeypot: :subtitle, scope: :budget_investment

    helper_method :resource_model, :resource_name
    respond_to :html, :js

    def index
      if @budget.finished?
        @investments = investments.winners.page(params[:page]).per(10).for_render
      else
        @investments = investments.page(params[:page]).per(10).for_render
      end

      @investment_ids = @investments.pluck(:id)
      load_investment_votes(@investments)
    end

    def new
    end

    def show
      @commentable = @investment
      @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)
      @related_contents = Kaminari.paginate_array(@investment.relationed_contents).page(params[:page]).per(5)
      set_comment_flags(@comment_tree.comments)
      load_investment_votes(@investment)
      @investment_ids = [@investment.id]
    end

    def create
      @investment.author = current_user

      if @investment.save
        Mailer.budget_investment_created(@investment).deliver_later
        redirect_to budget_investment_path(@budget, @investment),
                    notice: t('flash.actions.create.budget_investment')
      else
        render :new
      end
    end

    def destroy
      @investment.destroy
      redirect_to user_path(current_user, filter: 'budget_investments'), notice: t('flash.actions.destroy.budget_investment')
    end

    def vote
      @investment.register_selection(current_user)
      load_investment_votes(@investment)
      respond_to do |format|
        format.html { redirect_to budget_investments_path(heading_id: @investment.heading.id) }
        format.js
      end
    end

    def suggest
      @resource_path_method = :namespaced_budget_investment_path
      @resource_relation    = resource_model.where(budget: @budget).apply_filters_and_search(@budget, params, @current_filter)
      super
    end

    def redirect_to_new_url
      investment = Budget::Investment.where(original_spending_proposal_id: params['id']).first
      redirect_to budget_investment_path(investment.budget.slug, params['id'], spending: true) if investment.present?
    end

    def json_data
      investment =  Budget::Investment.find(params[:id])
      data = {
        investment_id: investment.id,
        investment_title: investment.title,
        budget_id: investment.budget.id
      }.to_json

      respond_to do |format|
        format.json { render json: data }
      end
    end

    private

      def resource_model
        Budget::Investment
      end

      def resource_name
        "budget_investment"
      end

      def load_investments
        @investments = @investments.apply_filters_and_search(@budget, params, @current_filter).send("sort_by_#{@current_order}")
        @investments = @investments.page(params[:page]).per(10).for_render
      end

      def load_investment_votes(investments)
        @investment_votes = current_user ? current_user.budget_investment_votes(investments) : {}
      end

      def set_random_seed
        if params[:order] == 'random' || params[:order].blank?
          seed = params[:random_seed] || session[:random_seed] || rand
          params[:random_seed] = seed
          session[:random_seed] = params[:random_seed]
        else
          session[:random_seed] = nil
          params[:random_seed] = nil
        end
      end

      def investment_params
        params.require(:budget_investment)
              .permit(:title, :description, :heading_id, :tag_list,
                      :organization_name, :location, :terms_of_service, :skip_map,
                      image_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                      map_location_attributes: [:latitude, :longitude, :zoom])
      end

      def load_investment
        @investment = if params['spending'] == 'true'
                        @budget.investments.where(original_spending_proposal_id: params['id']).first
                      else
                        @budget.investments.find(params['id'])
                      end
      end

      def load_ballot
        query = Budget::Ballot.where(user: current_user, budget: @budget)
        @ballot = @budget.balloting? ? query.first_or_create : query.first_or_initialize
      end

      def load_heading
        if params[:heading_id].present?
          load_heading_from_slug
          load_assigned_heading
          set_heading_id_from_slug
        end
      end

      def load_heading_from_slug
        @heading = @budget.headings.find_by(slug: params[:heading_id]) || @budget.headings.find_by(id: params[:heading_id])
      end

      def load_assigned_heading
        @assigned_heading = @ballot.try(:heading_for_group, @heading.try(:group))
      end

      def set_heading_id_from_slug
        params[:heading_id] = @heading.try(:id)
      end

      def load_categories
        @categories = ActsAsTaggableOn::Tag.category.order(:name)
      end

      def tag_cloud
        TagCloud.new(Budget::Investment, params[:search])
      end

      def load_budget
        @budget = Budget.find_by(slug: params[:budget_id]) || Budget.find_by(id: params[:budget_id])
        raise ActionController::RoutingError, 'Not Found' if @budget.blank?
      end

      def set_view
        @view = (params[:view] == "minimal") ? "minimal" : "default"
      end

      def investments
        if @current_order == 'random'
          @investments.apply_filters_and_search(@budget, params, @current_filter)
                      .send("sort_by_#{@current_order}", params[:random_seed])
        else
          @investments.apply_filters_and_search(@budget, params, @current_filter)
                      .send("sort_by_#{@current_order}")
        end
      end

  end
end
