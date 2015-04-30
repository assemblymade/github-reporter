class Githubber

  def self.auth_token
    auth_token = ENV['GITHUB_AUTH_TOKEN']
  end

  require 'github_api'
  require_relative 'remote'
  require 'json'
  require_relative 'pr'

  def self.all_commits_by_user_on_repo(user, repo_name, author=nil, since=nil, path=nil)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string, auto_pagination: true, per_page: 100
    return github.repos.commits.all user, repo_name, author: author
  end

  def self.last_commit_on_repo(owner, repo_name)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string, per_page: 1
    t = github.repos.commits.list owner, repo_name
    return t[0].sha
  end

  def self.list_collaborators_on_repo(repo_name)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    return github.repos repo: repo_name
  end

  def self.repos_on_user(user)
    Github.repos.list user: user
  end

  def self.repos_on_org(org)
    Github.repos.list org: org
  end

  def self.single_commit(repo_name, owner, sha)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    return github.repos.commits.get user: owner, repo: repo_name, sha: sha
  end

  def self.changes_one_commit(repo_name, owner, sha)
    commit_data = self.single_commit(repo_name, owner, sha)
    results = {}
    results['total_changes'] = commit_data.stats.total
    results['changes_by_file'] = []

    commit_data.files.each do |file|
      file_changes = {}
      file_changes['changes'] = file.changes
      file_changes['filename'] = file.filename
      file_changes['deletions'] = file.deletions
      file_changes['additions'] = file.additions
      results['changes_by_file'] << file_changes
    end
    results['changes_by_file'].sort_by{|a| -a['changes'] }
    results['commit_date'] = Time.iso8601(commit_data.commit.committer.date).to_i
    if commit_data.parents[0].nil?
      results['preceding_sha'] = nil
    else
      results['preceding_sha'] = commit_data.parents[0].sha
    end
    results['sha'] = sha
    begin

      results['committer'] = commit_data['committer']['login']
    rescue
      puts "ERROR WITH COMMITTER #{sha}"
    end
    results['message'] = commit_data['commit']['message']
    results
  end

  def self.get_commit_history(n_commits, repo_name, owner, starting_sha)
    history = []
    commit = changes_one_commit(repo_name, owner, starting_sha)

    history << commit

    (1..n_commits-1).each do |a|
      previous_commit = commit['preceding_sha']
      commit = changes_one_commit(repo_name, owner, previous_commit)
      history << commit
    end
    history.reverse
    history
  end

  def self.get_commits_inside_pr(repo_name, owner, pr_number)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    return github.pull_requests.files repo_name, owner, pr_number
  end

  def self.get_commit_fractions_from_pr(pr_data, owner, repo_name)
    pr_number = pr_data['number']
    pr_commits_data = self.get_commits_inside_pr(repo_name, owner, pr_number)
    committers = {}
    ss = 0
    puts "pr commits data #{pr_commits_data}"
    pr_commits_data.each do |a|
      sha = a['sha']

      commit = self.single_commit(repo_name, owner, sha)
      committer = commit['author']['login']
      files = commit['files']

      s = 0
      files.each{|a| s = s + a['changes']}
      ss = ss + s

      if committers.include?(committer)
        committers[committer] += s
      else
        committers[committer] = s
      end
    end
    committers.each do |k, v|
      committers[k] = v.to_f / ss
    end
    committers
  end

  def self.commit_history_since(history_length_int, repo_name, owner, starting_sha)
    history = self.changes_one_commit(repo_name, owner, starting_sha)
    start_time = history['commit_date']
    total_history = []
    total_history << history

    t = start_time - history['commit_date']

    while t < history_length_int
      sha = history['preceding_sha']
      if sha.nil?
        t=history_length_int
      else
        history = self.changes_one_commit(repo_name, owner, sha)
        t = start_time - history['commit_date']
        total_history << history
      end
    end
    total_history
  end

  def self.normalize_committers(file_data)
    (0..file_data.count-1).each do |a|
      s = 0
      file_data[a][1]['committers'].each{|k, v| s = s + v }
      if s > 0
        file_data[a][1]['committers'].each do |k, v|
          file_data[a][1]['committers'][k] = file_data[a][1]['committers'][k].to_f / s
        end
      end
    end
    file_data
  end

  def self.most_changed_files(history_data)
    files = {}
    history_data.each do |h|
      committer = h['committer']
      sha = h['sha']
      h['changes_by_file'].each do |f|
        if files.include?(f['filename'])
          if files[f['filename']]['committers'].include?(committer)
            files[f['filename']]['committers'][committer] += f['changes']
          else
            files[f['filename']]['committers'][committer] = f['changes']
          end

          files[f['filename']]['changes'] += f['changes']
          files[f['filename']]['deletions'] += f['deletions']
          files[f['filename']]['additions'] += f['additions']
          files[f['filename']]['change_dates'] << h['commit_date']
          if files[f['filename']]['commits'].has_key?(sha)
            files[f['filename']]['commits'][sha][0] += f['changes']
          else
            files[f['filename']]['commits'][sha] = [f['changes'], committer, h['message']]
          end
        else
          filedata = {}
          filedata['committers'] = {}
          filedata['commits'] = {}
          filedata['commits'][sha] = [f['changes'], committer, h['message']]
          filedata['committers'][committer] = f['changes']
          filedata['changes'] = f['changes']
          filedata['deletions'] = f['deletions']
          filedata['additions'] = f['additions']
          filedata['change_dates'] = [h['commit_date']]
          files[f['filename']] = filedata
        end
      end
    end
    files = files.sort_by{|a, b| -b['changes']}
    self.normalize_committers(files)
  end

  def self.commit_history(history_length, repo_name, owner)
    last_commit = self.last_commit_on_repo(owner, repo_name)
    history_data = commit_history_since(history_length, repo_name, owner, last_commit)
    changed_files = self.most_changed_files(history_data)
    results = {}
    results['history'] = history_data
    results['changed_files'] = changed_files
    results
  end

  def self.commit_change_stats(commit_history)
    s = 0
    commit_history['history'].each do |a|
      changes = a['total_changes']
      s += changes
    end
    average = s/commit_history['history'].count.to_f
    v = 0
    commit_history['history'].each do |a|
      v = v + (average - a['total_changes']) ** 2
    end
    v = v / commit_history['history'].count
    standard_deviation = v ** 0.5

    [average, standard_deviation]
  end

  def self.important_commits(commit_history, m)
    r = self.commit_change_stats(commit_history)
    average = r[0]
    sd = r[1]
    puts "#{average}  #{sd}"
    commits = commit_history['history'].select{|a| a['total_changes'] > average + sd * m }.sort_by{|q| -q['total_changes']}
  end

  def self.important_files(commit_history, n)
    commit_history['changed_files'].sort_by{|k, v| -v['changes']}.take(n)
  end

  def self.pull_requests(user, repo_name, time_limit=nil)
    prs = self.list_pull_requests(user, repo_name)
    if time_limit
      timenow = Time.now.to_i
      prs = prs.select{|a| a.closed_at}.select{|a| timenow - Time.iso8601(a.closed_at).to_i < time_limit}
    end
    r = []
    n = 1
    prs.each do |pr|
      puts n
      n = n + 1
      sha = pr.merge_commit_sha
      if !sha.nil? && pr.state == "closed"
        #begin
          commit = self.single_commit(repo_name, user, sha)
          d = {}
          d['title'] = pr.title
          d['url'] = pr['html_url']
          d['commit_sha']=sha
          d['stats'] = commit['stats']
          d['merger'] = commit['committer']['login']
          d['committers'] = self.get_commit_fractions_from_pr(pr, user, repo_name)

          d['created_at'] = Time.iso8601(pr.created_at).to_i
          d['files'] = commit['files'].map{|a| [a['filename'], [['changes', a['changes'] ], ['additions', a['additions']], ['deletions', a['deletions'] ] ].to_h ] }
          r << d
        #rescue
        # puts "error getting #{sha} for #{pr.title}"
        #end
      end
    end
    r
  end

  def self.find_important_pull_requests(prs, sd, time_limit=nil)
    s = 0
    v = 0
    timenow = Time.now.to_i
    if time_limit
      prs = prs.select{|a| (timenow - a['created_at']) < time_limit }
    end

    prs.each{|a| s += a['stats']['total'] }
    average_changes_per_pr = s / prs.count.to_f

    prs.each do |a|
      v += (average_changes_per_pr - a['stats']['total']) ** 2
    end
    v = (v/prs.count.to_f) ** 0.5
    puts "variance = #{v}"
    m = v * sd
    puts "average #{average_changes_per_pr}"
    prs.select{|a| (a['stats']['total'] - average_changes_per_pr) > m  }.sort_by{|q| -q['stats']['total']}
  end

  def self.list_comments(user, repo_name)
    login_string = "#{self.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string, auto_pagination: true, per_page: 100, user: user, repo: repo_name
    github.repos.comments.list user, repo_name
  end

  def self.activity_chart_from_history(history)
    activity = []
    history.each do |a|
      s = a['total_changes']
      d = a['commit_date']
      activity << [d, s]
    end
  end

  def self.top_users_in_history(history)
    users = {}
    history.each do |a|
      sha = a['sha']
      user = a['committer']
      message = a['message']
      if message[0,5] != "Merge"
        changes = a['total_changes']
        filechanges = a['changes_by_file']
        if users.include?(user)
          users[user]['total'] = users[user]['total'] + changes
          users[user]['commits'] << sha
        else
          users[user] = {}
          users[user]['total'] = changes
          users[user]['files'] = {}
          users[user]['commits'] = [sha]
        end

        filechanges.each do |q|
          filename = q['filename']
          changes = q['changes']
          if users[user].include?(filename)
            users[user]['files'][filename] << [sha, changes, a['message'], a['committer']]
          else
            users[user]['files'][filename] = []
            users[user]['files'][filename] << [sha, changes, a['message'], a['committer']]
          end
        end
      end
    end
    users.each do |u|
      u[1]['files'] = u[1]['files'].to_a
      u[1]['files'].each do |f|
        f[1] = f[1].sort_by{|a| -a[1]}
      end
    end
    users.to_a.sort_by{|q| -q[1]['total']}
  end

  def self.compute_user_scores(users_data)
    n=0
    r=[]
    p = 1.5
    users_data.each do |a|
      m = p ** (-1 * n)
      r << [a[0], m.to_f]
      n += 1
    end
    r.to_h
  end

  def self.commit_scores(commits_data)
    n=0
    r=[]
    p = 1.5
    commits_data.each do |a|
      m = p ** (-1 * n)
      r << [a['sha'], m.to_f]
      n += 1
    end
    r.to_h
  end

  def self.pr_scores(pr_data)
    n=0
    r=[]
    p = 1.5
    pr_data.each do |a|
      m = p ** (-1 * n)
      r << [a['title'], m.to_f]
      n += 1
    end
    r.to_h
  end

  def self.all_history(user, repo_name, history_length)
    history = self.commit_history(history_length, repo_name, user)
    history['comments'] = self.list_comments(user, repo_name)
    history
  end

  def self.highlights_from_history(history, user, repo_name, history_length)
    sd = 0.2
    highlights = {}
    highlights['users'] = self.top_users_in_history(history['history'])
    highlights['prs'] = PR.pull_requests(user, repo_name, sd, history_length)
    highlights['files'] = history['changed_files'].take(3)
    highlights['commits'] = self.important_commits(history, sd)
    highlights['activity'] = self.activity_chart_from_history(history['history'])
    highlights
  end

  def self.highlights(user, repo_name, history_length)
    history = self.all_history(user, repo_name, history_length)
    return self.highlights_from_history(history, user, repo_name, history_length)
  end

  def self.user_highlight_key(user)
    t = Time.now.to_i
    t2 = t - (t % (86400*14))
    k = "GITHUB-USER-#{user}-#{t2}"
    k
  end
end
