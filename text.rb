class Text
  require_relative 'githubber'
  def self.pr_to_text(pr_data)
    highlight = {}
    highlight['label'] = pr_data['title']
    most_changed_files = self.get_most_changed_files_in_pr(pr_data).take(3)
    highlight['content'] = "###{pr_data['stats']['total']} total changes, by user"

    pr_data['committers'].each do |k, v|
      highlight['content'] = highlight['content'] + "- #{k} #{(v*100).to_f.round(2)}%"
    end
    highlight['content'] = highlight['content'] + "###Changed Files"
    most_changed_files.each do |a, b|
      highlight['content'] = highlight['content'] + "- #{a} -- #{b}"
    end

    highlight['content'] = highlight['content'] + "###Commit Messages"

    pr_data['commit_messages'].each do |cm|
      highlight['content'] = highlight['content'] + " - #{cm}"
    end

    highlight['content'] += "#####[Source Link](#{pr_data['url']})"

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

  def self.file_to_text(file_data, owner, repo_name)
    highlight = {}
    file_link = file_data[0]
    file_name = file_data[0].split('/').last
    if file_data[1]['deletions'] > file_data[1]['additions'] * 2
      file_text = "had tons of deletions by "
    elsif file_data[1]['additions'] > file_data[1]['deletions'] * 2
      file_text = "had tons of additions by "
    else
      file_text = "had many changes by "
    end

    total_changes = 0
    file_data[1]['committers'].each do |k, v|
      file_text = file_text + " --> #{k} who did #{(v*100).to_f.round(2)}%."
    end

    highlight['label'] = "#{file_name} heavily (#{file_data[1]['changes']}) changed on Github in #{owner}/#{repo_name}"
    highlight['content'] = "#{file_name} #{file_text}"
    highlight['why'] = "#{file_name} changed on Github"
    highlight['upsert_key'] = self.file_to_key(file_data, owner, repo_name)
    highlight
  end

  def self.file_to_key(file_data, owner, repo_name)
    t = Time.now.to_i
    t2 = t - (t % 86400*7)
    "GITHUB-FILES-#{file_data[0]}-#{t2}-owner-repo-name"
  end

  def self.user_to_text(user_data, repo_name)
    highlight = {}
    username = user_data[0]
    show_files = 10
    changes = user_data[1]['total']
    file_changes = user_data[1]['files'].count
    files_changed = user_data[1]['files'].take(show_files).sort_by{|a, b| -b}

    files_string = ""
    files_changed.each{|a, b| files_string = files_string + " - #{a} with #{b} changes"}

    if user_data[1]['files'].count > show_files
      files_string = files_string + " and #{file_changes - show_files} others"
    end

    highlight['label'] = "#{username} Github contributions"
    highlight['content'] = "#{username} worked on: #{files_string} with "
    highlight['why'] = "User made #{changes} changes across #{file_changes} files on Github"
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
