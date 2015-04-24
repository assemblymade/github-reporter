class Text
  def self.pr_to_text(pr_data)
    highlight = {}
    highlight['label'] = "Pull Request -- #{pr_data['title']}"
    highlight['key'] = "#{pr_data['key']}"
    most_changed_files = self.get_most_changed_files_in_pr(pr_data).take(3)
    highlight['content'] = "#{pr_data['stats']['total']} commits done by "

    pr_data['committers'].each do |k, v|
      highlight['content'] = highlight['content'] + "#{k} #{(v*100).to_f.round(2)}%<br/>"
    end

    most_changed_files.each do |a, b|
      highlight['content'] = highlight['content'] + "<br/>#{a} -- #{b}"
    end

    highlight['content'] = highlight['content'] + "<br/>Files"
    pr_data['commit_messages'].each do |cm|
      highlight['content'] = highlight['content'] + "<br/>cm"
    end

    highlight['why'] = "Merged Pull Request with above-average cumulative changes within the chosen time window"

    highlight['id'] =

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

  def self.file_to_text(file_data)
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

    file_data[1]['committers'].each do |k, v|
      file_text = file_text + " --> #{k} who did #{(v*100).to_f.round(2)}%."
    end

    highlight['label'] = "#{file_name} got lots of attention on github"
    highlight['content'] = "#{file_name} #{file_text}"
    highlight['why'] = "file was heavily changed in chosen time period"
    highlight
  end

  def self.user_to_text(user_data)
    highlight = {}
    username = user_data[0]
    show_files = 3
    changes = user_data[1]['total']
    file_changes = user_data[1]['files'].count
    files_changed = user_data[1]['files'].take(show_files).map{|a, b| a}

    files_string = ""
    files_changed.each{|a| files_string = files_string + "<br/> #{a}"}

    if user_data[1]['files'].count > show_files
      files_string = files_string + " and #{file_changes - show_files} others"
    end

    highlight['label'] = "#{username} made #{changes} changes"
    highlight['content'] = "#{username} editted these files <br/> #{files_string}"
    highlight['why'] = "User contributed many changes within chosen time period"
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
