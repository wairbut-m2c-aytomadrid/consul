module BudgetExecutionsHelper

  def spending_proposals?
    @budget.slug == '2016'
  end

  def filters_select_counts(status)
    @budget.investments.winners.with_milestones.select { |i| i.milestones
                                      .published.with_status.order_by_publication_date
                                      .last.status_id == status rescue false }.count
  end

end
