class RepoActivity
  def self.get_watchers(user, repo_name)
    login_string = "#{Githubber.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    github.activity.watching.list user: user, repo: repo_name
  end

  def self.get_stargazers(user, repo_name)
    login_string = "#{Githubber.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    return github.activity user: user, repo: repo_name
  end

  def self.list_commits_on_repo(user, repo_name)
    login_string = "#{Githubber.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string
    return github.repos.commits.list user: user, repo: repo_name
  end

  def self.unique_committers_in_history(user, repo_name)
    commit_history = self.list_commits_on_repo(user, repo_name)
    users = {}
    commit_history.each do |a|
      author = a['author']['login']
      if users.include?(author)
        users[author][0] += 1
      else
        commit_sha = a['sha']
        startdate =
        users[author] = [1, startdate]
      end
    end
    users
  end

end
