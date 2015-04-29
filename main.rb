class Main
  require_relative 'githubber'
  require_relative 'pr'
  require_relative 'text'
  require_relative 'remote'

  def self.present_highlights(user, repo_name, history_length_in_days)
    a = Githubber.highlights(user, repo_name, history_length_in_days * 86400)
    return Text.text_from_highlights(a)
  end

  def self.push_pr_highlights(owner, repo_name, time_length, org_slug)
    prs = PR.pull_requests(owner, repo_name, -10, time_limit=time_length)
    prs_text = prs.map{|a| Text.pr_to_text(a) }
    prs_text.each do |pr|
      self.send_highlight(pr, org_slug)
    end
  end

  def self.send_highlight(text_package, org_slug)
    url = "http://titan-api.herokuapp.com/changelogs/#{org_slug}/highlights"
    puts "SENDING HIGHLIGHT #{text_package} TO #{org_slug}"
    puts ""
    return Remote.post(url, text_package)
  end

  def self.push_user_highlights(owner, repo_name, time_length, org_slug)
    commit_history = Githubber.commit_history(time_length, repo_name, owner)
    users = Githubber.top_users_in_history(commit_history['history'])

    users.each do |u|
      m = Text.user_to_text(u, repo_name)
      self.send_highlight(m, org_slug)
    end
  end

  def self.push_files_highlights(owner, repo_name, time_length, org_slug, data)
    files = data['files']

    files.each do |file|
      file_text = Text.file_to_text(file, owner, repo_name)
      self.send_highlight(file_text, org_slug)
    end
  end

  def self.push_commits_highlights(owner, repo_name, time_length, top_n, org_slug, data)
    commits = data['commits']
    commits = commits.select{|a| a['message'][0,5] != "Merge" && !a['message'].nil? }.take(top_n)
    commits.each do |commit|
      commit_text = Text.commit_to_text(commit, owner, repo_name)
      self.send_highlight(commit_text, org_slug)
    end
  end

  def self.push_all(owner, repo_name, time_length_days, org_slug)
    time_length = time_length_days * 86400
    data = Githubber.highlights(owner, repo_name, time_length)
    #self.push_files_highlights(owner, repo_name, time_length, org_slug, data)
    #self.push_user_highlights(owner, repo_name, time_length, org_slug)
    self.push_pr_highlights(owner, repo_name, time_length, org_slug)
    self.push_commits_highlights(owner, repo_name, time_length, 3, org_slug, data)
  end

end
