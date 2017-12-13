module Notifiable
  extend ActiveSupport::Concern

  def notifiable_title
    case notifiable.class.name
    when "ProposalNotification"
      notifiable.proposal.title
    when "Comment"
      notifiable.commentable.title
    else
      notifiable.title
    end
  end

  def notifiable_action
    case notifiable_type
    when "ProposalNotification"
      "proposal_notification"
    when "Comment"
      "replies_to"
    else
      "comments_on"
    end
  end

  def notifiable_available?
    case notifiable.class.name
    when "ProposalNotification"
      check_availability(notifiable.proposal)
    when "Comment"
      check_availability(notifiable.commentable)
    else
      check_availability(notifiable)
    end
  end

  def check_availability(resource)
    resource.present? &&
    resource.try(:hidden_at) == nil &&
    resource.try(:retired_at) == nil
  end

  def linkable_resource
    notifiable.is_a?(ProposalNotification) ? notifiable.proposal : notifiable
  end
end
