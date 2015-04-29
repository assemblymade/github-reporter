class Text
  require_relative 'githubber'
  require 'date'

  def self.pr_content(pr_data)
    a="#{pr_data['title']}"
    if pr_data['state'] == "open"
      a += " Open PR by #{pr_data['merger']}"
    elsif pr_data.has_key?('merge_sha')
      a += " Merged PR by #{pr_data['merger']}"
    else
      a += " Closed PR by #{pr_data['merger']}"
    end
  end

  def self.pr_timestamp(pr_data)
    pr_data['created_at']
  end

  def self.pr_to_text(pr_data)
    highlight = {}
    highlight['content'] = self.pr_content(pr_data)
    highlight['event_timestamp'] = self.pr_timestamp(pr_data)
    highlight['upsert_key'] = pr_data['key']
    highlight
  end

  def self.commit_to_text(commit_data)
    if commit_data['commit_date']
      d = DateTime.strptime(commit_data['commit_date'].to_s,'%s').to_s
      d = DateTime.parse(d)
      d = d.strftime('%b %d %Y')
    else
      d=nil
    end
    a = "#{commit_data['message']} committed by #{commit_data['committer']}"
    if d
      a += " on #{d}"
    end
    a
  end

  def self.file_content(file_data)
  end

  def self.file_timestamp(file_data)
  end

  def self.file_to_text(file_data, owner, repo_name)
    highlight = {}
    highlight['content'] = self.file_content(file_data)
    highlight['event_timestamp'] = self.file_timestamp(file_data)
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
    a = "###{username} was active on #{repo_name}"
    a += "\n###Files Changed"
    user_data[1]['files'].each do |file|
      sumchanges = 0
      file[1].each{|q| sumchanges += q[1]}
      a += "\n      #{file[0]} : #{sumchanges} changes"


      file[1].each do |q|
        if q[2].length > 0
          q[2].sub("\n", "  ")
          a += "\n     #{q[2]}"
        end
      end
    end
    a
  end

  def self.user_why(user_data, repo_name)
    files_n = user_data[1]['files'].count
    change_number = 0
    user_data[1]['files'].each do |a|
      a[1].each do |b|
        change_number += b[1]
      end
    end
    "User made #{change_number} changes across #{files_n} files on #{repo_name}"
  end

  def self.user_to_text(user_data, repo_name)
    username = user_data[0]
    highlight = {}
    highlight['label'] = self.user_label(user_data, repo_name)
    highlight['content'] = self.user_content(user_data, repo_name)
    highlight['why'] = self.user_why(user_data, repo_name)
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
