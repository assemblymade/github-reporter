class Activity

  require_relative 'main'

  def self.hundred_public_events(owner, repo_name)  #only last 100
    login_string = "#{Githubber.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string, auto_pagination: false, per_page: 100
    github.activity.events.network owner, repo_name
  end

  def self.public_events(owner, repo_name, org_slug)
    events = self.hundred_public_events(owner, repo_name)

    events.each do |event|
      text = self.event_to_text(event)
      if text.has_key?('content')
        Main.send_highlight(text, org_slug)
      end
    end
  end

  def self.event_to_text(event_data)
    highlight = {}
    highlight['occurred_at'] = event_data['created_at']
    if event_data['category'] == "PushEvent"
      highlight = self.push_event_to_text(event_data, highlight)
    elsif event_data['category'] == "IssueCommentEvent" or event_data['type'] == "PullRequestReviewCommentEvent"
      highlight = self.issue_comment_event_to_text(event_data, highlight)
    elsif event_data['category'] == "ForkEvent"
      highlight = self.fork_event_to_text(event_data, highlight)
    elsif event_data['category'] == "WatchEvent"
      highlight = self.watch_event_to_text(event_data, highlight)
    end
    highlight
  end

  def self.issue_comment_event_to_text(event_data, highlight)
    commenter = event_data['actor']['login']
    comment = event_data['payload']['comment']['body']
    highlight['score'] = 0.7
    highlight['content'] = "#{commenter} commented '#{comment}' on #{event_data['repo']['name']}"
    highlight['category'] = "github CommentEvent"
    highlight['actors'] = [commenter]
    highlight['upsert_key'] = "GH-COMMENT-#{event_data['created_at']}-#{event_data['repo']}"
    highlight
  end

  def self.push_event_to_text(event_data, highlight)
    pusher = event_data['actor']['login']
    highlight['score'] = 0.8
    highlight['content'] = "#{pusher} pushed directly to #{event_data['repo']['name']}"
    highlight['category'] = "github PushEvent"
    highlight['upsert_key'] = "GH-PUSH-#{event_data['payload']['head']}"
    highlight['actors'] = [pusher]
    highlight
  end

  def self.watch_event_to_text(event_data, highlight)
    if event_data['payload']['action'] == "started"
      watcher = event_data['actor']['login']
      highlight['upsert_key'] = "GH-WATCH-#{watcher}-#{event_data['repo']}"
      highlight['actors'] = [watcher]
      highlight['content'] = "#{watcher} is watching the #{event_data['repo']} repo"
      highlight['category'] = "github WatchEvent"
      highlight['score'] = 0.2
      highlight
    end
  end

  def self.fork_event_to_text(event_data, highlight)
    forker = event_data['actor']
    repo = event_data['repo']['name']
    highlight['upsert_key'] = "GH-FORK-#{forker}-#{repo}-#{event_data['created_at']}"
    highlight['actors'] = [forker]
    highlight['content'] = "#{forker.capitalize} forked #{repo}"
    highlight['category'] = 'github ForkEvent'
    highlight['score'] = 1.0
    highlight
  end

end
