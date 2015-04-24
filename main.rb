class Main
  require_relative 'githubber'
  require_relative 'pr'
  require_relative 'text'
  require_relative 'remote'

  def self.present_highlights(user, repo_name, history_length_in_days)
    a = Githubber.highlights(user, repo_name, history_length_in_days * 86400)
    return Text.text_from_highlights(a)
  end

  def self.push_pr_highlights(owner, repo_name, time_length)
    standard_deviations = 0.3
    prs = PR.pull_requests(owner, repo_name, standard_deviations, time_limit=time_length)
    prs_text = prs.map{|a| Text.pr_to_text(a) }

    prs_text.each do |pr|
      self.send_highlight(pr)
    end
  end

  def self.send_highlight(text_package)
    url = "http://titan-api.herokuapp.com/changelogs/assembly/highlights"
    puts "SENDING HIGHLIGHT #{text_package}"
    puts ""
    return Remote.post(url, text_package)
  end

  def self.push_user_highlights(owner, repo_name, time_length)
    commit_history = Githubber.commit_history(time_length, repo_name, owner)
    users = Githubber.top_users_in_history(commit_history['history'])

    users.each do |u|
      m = Text.user_to_text(u, repo_name)
      self.send_highlight(m)
    end
  end

  def self.push_files_highlights(owner, repo_name, time_length)
    files = Githubber.highlights(owner, repo_name, time_length)['files']

    files.each do |file|
      file_text = Text.file_to_text(file, owner, repo_name)
      self.send_highlight(file_text)
    end
  end

  def self.push_all(owner, repo_name, time_length_days)
    time_length = time_length_days * 86400
    self.push_files_highlights(owner, repo_name, time_length)
    self.push_user_highlights(owner, repo_name, time_length)
    self.push_pr_highlights(owner, repo_name, time_length)
  end

end
