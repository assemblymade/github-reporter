class Text
  require_relative 'githubber'
  def self.pr_to_text(pr_data)
    highlight = {}
    highlight['label'] = pr_data['title']
    most_changed_files = self.get_most_changed_files_in_pr(pr_data).take(3)
    highlight['content'] = "###{pr_data['stats']['total']} total changes, by user"

    pr_data['committers'].each do |k, v|
      highlight['content'] = highlight['content'] + "\n- #{k} #{(v*100).to_f.round(2)}%"
    end
    highlight['content'] = highlight['content'] + "###Changed Files"
    most_changed_files.each do |a, b|
      highlight['content'] = highlight['content'] + "\n- #{a} -- #{b}"
    end

    highlight['content'] = highlight['content'] + "\n###Commit Messages"

    pr_data['commit_messages'].each do |cm|
      highlight['content'] = highlight['content'] + "\n- #{cm}"
    end

    highlight['content'] += "\n#####[Source Link](#{pr_data['url']})"

    if pr_data['state'] == "open"
      state = "Open"
    else
      state = "Closed"
    end
    highlight['why'] = "#{state} Github Pull Request with #{most_changed_files.count} files changed"

    highlight['upsert_key'] = pr_data['key']

    highlight
  end

  def self.get_most_changed_files_in_pr(pr_data)
    pr_data['files'].sort_by{|a, b| -b['changes']}

    filenames = pr_data['files'].map{|a, b| a}.map{|a| a.split('/').last}

    file_event_content = pr_data['files'].map do |a, b|
      if b['additions'] > b['deletions'] * 2
        event_text = "#{b['additions']} additions"
      elsif b['deletions'] > b['additions'] * 2
        event_text = "#{b['deletions']} deletions"
      else
        event_text = "#{b['deletions'] + b['additions']} changes"
      end
      event_text
    end

    events = []
    (0..filenames.count-1).each do |a|
      events << [filenames[a], file_event_content[a]]
    end
    events.to_h
  end

  def self.commits_to_text(commit_data)
  end

  def self.file_content(file_data)
    filename = file_data[0].split('/').last
    filepath = file_data[0]
    a = "###{filename} received lots of love"
    a += "\n#{filepath}"

    a += "\n####Commits"
    commits = file_data[1]['commits'].sort_by{|k, v| -v}
    commits.each do |c, d|
      a += "\n      - #{c}  #{d} changes"
    end

    a += "\n\n####Contributions by"
    file_data[1]['committers'].each do |q|
      committer_name = q[0]
      additions_count = (file_data[1]['additions'] * q[1]).to_i
      deletions_count = (file_data[1]['deletions'] * q[1]).to_i
      percent =
      a += "\n-######{committer_name}"
      a += "\n     -#{additions_count} additions, #{deletions_count} deletions, #{percent}% of total"
    end
    a
  end

  def self.file_to_text(file_data, owner, repo_name)
    highlight = {}
    file_link = file_data[0]
    file_name = file_data[0]#.split('/').last

    top_committer = file_data[1]['committers'].sort_by{|a, b| -b}[0][0]
    committers_n = file_data[1]['committers'].count
    and_others_text = committers_n > 1 ? " and #{committers_n - 1} others" : ""

    highlight['label'] = "#{file_name} (#{file_data[1]['changes']}) changes in #{repo_name} by #{top_committer}#{and_others_text}"
    highlight['content'] = self.file_content(file_data)
    highlight['why'] = "#{file_name} changed on Github"
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
    "Github activity by #{username} on #{repo_name}"
  end

  def self.user_content(user_data, repo_name)
    username = user_data[0]
    a = "###{username} was active on #{repo_name}"
    a += "\n###Files Changed"
    user_data[1]['files'].each do |file|
      sumchanges = 0
      file[1].each{|q| sumchanges += q[1]}
      a += "\n      -#{file[0]} : #{sumchanges} changes"

      file[1].each do |q|
        a += "\n          -#{q[2]} : by #{q[0]}"
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
    "User made #{change_number} changes across #{files_n} on #{repo_name}"
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
