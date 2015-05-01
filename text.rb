class Text
  require_relative 'githubber'
  require 'date'

  def self.pr_content(pr_data)
    a = "#{pr_data['merger']} "
    if pr_data['state'] == "open"
      a += " opened"
    elsif pr_data.has_key?('merge_sha')
      a += " merged"
    else
      a += " closed"
    end
    a += " PR: #{pr_data['title']}"
    a
  end

  def self.pr_timestamp(pr_data)
    pr_data['created_at']
  end

  def self.pr_to_text(pr_data)
    highlight = {}
    highlight['label'] =
    highlight['content'] = self.pr_content(pr_data)
    highlight['occurred_at'] = self.pr_timestamp(pr_data)
    highlight['category'] = "pr"
    highlight['score'] = 1.0
    highlight['occurred_at'] = Time.at(highlight['occurred_at']).iso8601
    highlight['upsert_key'] = pr_data['key']
    highlight['actors'] = pr_data['committers'].keys()
    highlight
  end

  def self.commit_to_text(commit_data, owner, repo_name, commit_score)
    if commit_data['commit_date']
      d = DateTime.strptime(commit_data['commit_date'].to_s,'%s').to_s
      d = DateTime.parse(d)
      d = d.strftime('%b %d %Y')
    else
      d=nil
    end
    a = "#{commit_data['message']}"
    highlight = {}
    highlight['content'] = a
    highlight['label'] = "#{commit_data['committer']} committed on #{repo_name}"
    highlight['category'] = "github commit"
    highlight['score'] = commit_score
    highlight['actors'] = [commit_data['committer']]
    highlight['occurred_at'] = commit_data['commit_date']
    highlight['occurred_at'] = Time.at(highlight['occurred_at']).iso8601
    highlight['upsert_key'] = "GITHUB-COMMIT-#{commit_data['sha']}"
    highlight
  end

  def self.file_content(file_data)
  end

  def self.file_timestamp(file_data)
  end

  def self.file_to_text(file_data, owner, repo_name)
    highlight = {}
    highlight['content'] = self.file_content(file_data)
    highlight['label'] = ""
    highlight['occurred_at'] = self.file_timestamp(file_data)
    highlight['upsert_key'] = self.file_to_key(file_data, owner, repo_name)
    highlight
  end

  def self.file_to_key(file_data, owner, repo_name)
    t = Time.now.to_i
    t2 = t - (t % (86400*14))
    "GITHUB-FILES-#{file_data[0]}-#{t2}-owner-repo-name"
  end

  def self.user_label(user_data, repo_name)
    username = user_data[0]
    commits = user_data[1]['commits'].uniq.count
    "#{username}: #{commits} commits on #{repo_name}"
  end

  def self.user_content(user_data, repo_name)
    username = user_data[0]
    files = user_data[1]['files'].sort_by{|e| s=0;e[1].each{|t| s=s+t[1]}; -s}
    if files.count >= 2
      a = "Changes to  #{files[0][0].split('/').last}, #{files[1][0].split('/').last}, and #{files.count-2} other file"
    elsif files.count == 2
      a = "Changes to #{files[0][0].split('/').last}, #{files[1][0].split('/').last}, and #{files.count-2} other files"
    elsif files.count == 1
      a = "Changes to #{files[0][0].split('/').last}"
    end
    a
  end

  def self.user_to_text(user_data, repo_name, user_scores)
    username = user_data[0]
    highlight = {}
    highlight['content'] = self.user_content(user_data, repo_name)
    highlight['occurred_at'] = nil
    highlight['label'] = "#{user_data[0]}'s Github activity'"
    highlight['category'] = "user commits"
    highlight['actors'] = [username]
    highlight['score'] = user_scores[username]
    highlight['upsert_key'] = Githubber.user_highlight_key(username)
    highlight
  end

  def self.text_from_highlights(highlights)
    t = {}
    t['users'] = highlights['users'].map{|a| self.user_to_text(a)}
    t['prs'] = highlights['prs'].map{|a| self.pr_to_text(a)}
    t['files'] = highlights['files'].map{|a| self.file_to_text(a)}
    t['commits'] = highlights['commits'].map{|a| self.commits_to_text(a)}
    t
  end
end
