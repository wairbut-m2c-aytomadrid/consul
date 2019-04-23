module Custom::PollsHelper
  def show_link_to_first_voting?(poll)
    poll.starts_at == Time.parse("13-02-2017") && poll.ends_at == Time.parse("19-02-2017")
  end
end
