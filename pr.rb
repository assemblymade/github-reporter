class PR
  require 'github_api'
  require_relative 'remote'
  require_relative 'githubber'
  require 'json'

  def self.auth_token
    auth_token = ENV['GITHUB_AUTH_TOKEN']
  end

  def self.list_pull_requests(user, repo_name, state)
    login_string = self.auth_token
    github = Github.new basic_auth: login_string, auto_pagination: true, per_page: 100, user: user, repo: repo_name
    github.pull_requests.list state: state
  end

  def self.commits_on_pr(user, repo_name, number)
    login_string = self.auth_token
    github = Github.new basic_auth: login_string, auto_pagination: true, per_page: 100, user: user, repo: repo_name
    github.pull_requests.commits user, repo_name, number
  end

  def self.all_pull_requests(user, repo_name)
    self.list_pull_requests(user, repo_name, 'all')
  end

  def self.closed_pull_requests(user, repo_name)
    self.list_pull_requests(user, repo_name, 'closed')
  end

  def self.open_pull_requests(user, repo_name)
    self.list_pull_requests(user, repo_name, 'open')
  end

  def self.format_pr(user, repo_name, pr)
    d = {}
    d['title'] = pr['title']
    d['url'] = pr['html_url']
    d['state'] = pr['state']
    sha = pr.merge_commit_sha
    if sha
      begin
        merge_commit = Githubber.single_commit(repo_name, user, sha)
        d['stats'] = merge_commit['stats']
        d['merge_sha']=sha
        d['files'] = merge_commit['files'].map{|a| [a['filename'], [['changes', a['changes'] ], ['additions', a['additions']], ['deletions', a['deletions'] ] ].to_h ] }
        d['merger'] = merge_commit['committer']['login']
      rescue
        puts "error loading commit #{sha}"
      end
    end

    number = pr['number']
    begin
      commits_inside_pr = self.commits_on_pr(user, repo_name, number)
      d['commit_messages'] = commits_inside_pr.map{|a| [a['commit']['message'], a['commit']['url']]}
      r = commits_inside_pr.map{|a| a['commit']['committer']['name'] }
      d['committers'] = {}
      r.each do |q|
        d['committers'][q] = r.select{|a| a==q}.count.to_f / r.count
      end
    rescue
      puts "error getting commits inside PR #{number}"
    end

    d['key'] = self.generate_pr_highlight_key(number, repo_name, user)
    d['created_at'] = Time.iso8601(pr.created_at).to_i
    d
  end

  def self.filter_prs(prs, sd)
    s = 0
    prs.each do |a|
      if a.has_key?('stats')
        s = s + a['stats']['total']
      end
    end
    average_changes_per_pr = s / prs.count.to_f

    v=0
    prs.each do |a|
      if a.has_key?('stats')
        v += (average_changes_per_pr - a['stats']['total']) ** 2
      end
    end
    v = (v/prs.count.to_f) ** 0.5
    m = v * sd
    prs.select{|a| a.has_key?('stats') }.select{|a| (a['stats']['total'] - average_changes_per_pr) > m  }.sort_by{|q| -q['stats']['total']}
  end

  def self.pull_requests(user, repo_name, standard_deviations=nil, time_limit=nil)
    prs = self.all_pull_requests(user, repo_name)
    if time_limit
      timenow = Time.now.to_i
      prs = prs.select do |a|
        if a.closed_at
          timenow - Time.iso8601(a.closed_at).to_i < time_limit
        else
          true
        end
      end
    end
    r = []
    prs

    prs.each do |pr|
      r << self.format_pr(user, repo_name, pr)
    end

    if standard_deviations
      self.filter_prs(r, standard_deviations)
    else
      r
    end
  end

  def self.generate_pr_highlight_key(number, repo_name, owner)
    t = Time.now.to_i
    t2 = t - (t % (86400*14))
    k = "GITHUB-PR-#{owner}-#{repo_name}-#{number}-#{t2}"
    return k
  end

end
