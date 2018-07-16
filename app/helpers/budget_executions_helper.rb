module BudgetExecutionsHelper

  def winner_investments(heading)
    if params[:status].present?
      heading.investments
             .selected
             .sort_by_ballots
             .joins(:milestones)
             .distinct
             .where(milestones: {status_id: params[:status]})
    else
      heading.investments
             .selected
             .sort_by_ballots
             .joins(:milestones)
             .distinct
    end
  end

end
