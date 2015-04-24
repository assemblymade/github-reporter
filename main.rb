class Main
  require_relative 'githubber'
  require_relative 'pr'
  require_relative 'text'

  def self.present_highlights(user, repo_name, history_length_in_days)
    a = Githubber.highlights(user, repo_name, history_length_in_days * 86400)
    return Text.text_from_highlights(a)
  end

  def self.push_pr_highlights(owner, repo_name, time_length)
    standard_deviations = 0.3
    prs = PR.pull_requests(user, repo_name, standard_deviations, time_limit=nil)
    prs_text = prs.map{|a| Text.pr_to_text(a) }

    prs_text.each do |pr|
    end
  end

  def self.send_pr_highlight(pr_text_package)
    
  end


end
