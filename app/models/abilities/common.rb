module Abilities
  class Common
    include CanCan::Ability

    def initialize(user)
      merge Abilities::Everyone.new(user)

      can [:read, :update], User, id: user.id

      can :read, Debate
      can :update, Debate do |debate|
        debate.editable_by?(user)
      end

      can :read, Proposal
      can :update, Proposal do |proposal|
        proposal.editable_by?(user)
      end
      can [:retire_form, :retire], Proposal, author_id: user.id

      can [:read, :welcome], SpendingProposal

      can :read, Legislation::Proposal
      cannot [:edit, :update], Legislation::Proposal do |proposal|
        proposal.editable_by?(user)
      end
      can [:retire_form, :retire], Legislation::Proposal, author_id: user.id

      can :create, Comment
      can :create, Debate
      can :create, Proposal
      can :create, Legislation::Proposal

      can :suggest, Debate
      can :suggest, Proposal
      can :suggest, Legislation::Proposal
      can :suggest, ActsAsTaggableOn::Tag

      can [:flag, :unflag], Comment
      cannot [:flag, :unflag], Comment, user_id: user.id

      can [:flag, :unflag], Debate
      cannot [:flag, :unflag], Debate, author_id: user.id

      can [:flag, :unflag], Proposal
      cannot [:flag, :unflag], Proposal, author_id: user.id

      can [:flag, :unflag], Legislation::Proposal
      cannot [:flag, :unflag], Legislation::Proposal, author_id: user.id

      can [:create, :destroy], Follow

      can [:destroy], Document, documentable: { author_id: user.id }

      can [:destroy], Image, imageable: { author_id: user.id }

      can [:create, :destroy], DirectUpload

      unless user.organization?
        can :vote, Debate
        can :vote, Comment
      end

      if user.level_two_or_three_verified?
        can :create, SpendingProposal

        can :vote, Legislation::Proposal
        can :vote_featured, Legislation::Proposal
        can :create, Legislation::Answer

        can :create, Budget::Investment,               budget: { phase: "accepting" }
        can :suggest, Budget::Investment,              budget: { phase: "accepting" }
        can :destroy, Budget::Investment,              budget: { phase: ["accepting", "reviewing"] }, author_id: user.id
        can [:create, :destroy], Budget::Recommendation

        can :create, DirectMessage
        can :show, DirectMessage, sender_id: user.id

        if user.old_enough_to_participate?
          can :vote, Proposal
          can :vote_featured, Proposal
          can :vote, SpendingProposal

          can [:show, :create], Budget::Ballot,          budget: { phase: "balloting" }
          can [:create, :destroy], Budget::Ballot::Line, budget: { phase: "balloting" }
          # This line must happen after Budget::Ballot is used (in the previous lines);
          # otherwise Rails autoloader gets confused in Dev
          can :show, ::Ballot
          if Setting["feature.spending_proposal_features.final_voting_allowed"].present?
            can [:create, :destroy], ::BallotLine
          end
          can :vote, Budget::Investment,                 budget: { phase: "selecting" }
          can [:show, :create], Budget::Ballot,          budget: { phase: "balloting" }
          can [:create, :destroy], Budget::Ballot::Line, budget: { phase: "balloting" }

          can :answer, Poll do |poll|
            poll.answerable_by?(user)
          end
          can :answer, Poll::Question do |question|
            question.answerable_by?(user)
          end
        end
      end

      can [:create, :show], ProposalNotification, proposal: { author_id: user.id }

      if user.forum?
        can :vote, SpendingProposal
        can [:create, :destroy], ::BallotLine
      end

      can [:create, :read], Answer
      can :create, Annotation
      can [:update, :destroy], Annotation, user_id: user.id

      can [:create], Topic
      can [:update, :destroy], Topic, author_id: user.id

      can :disable_recommendations, [Debate, Proposal]
    end
  end
end
