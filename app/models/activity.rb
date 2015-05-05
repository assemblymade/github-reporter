class Activity
  def self.hundred_public_events(owner, repo_name)  #only last 100
    login_string = "#{Githubber.auth_token}:x-oauth-basic"
    github = Github.new basic_auth: login_string, auto_pagination: false, per_page: 100
    github.activity.events.network owner, repo_name
  end

  def self.public_events(owner, repo_name, org_slug)
    begin
      events = self.hundred_public_events(owner, repo_name)
      events.each do |event|
        text = self.event_to_text(event)
        if text.has_key?('content')
          Main.send_highlight(text, org_slug)
        end
      end
    rescue
      puts "COULD NOT GET PUBLIC EVENTS FOR #{repo_name}"
    end
  end

  def self.event_to_text(event_data)
    highlight = {}
    highlight['occurred_at'] = event_data['created_at']
    #if event_data['type'] == "PushEvent"
    #  highlight = self.push_event_to_text(event_data, highlight)
    if event_data['type'] == "IssueCommentEvent" or event_data['type'] == "PullRequestReviewCommentEvent"
      highlight = self.issue_comment_event_to_text(event_data, highlight)
    elsif event_data['type'] == "ForkEvent"
      highlight = self.fork_event_to_text(event_data, highlight)
    elsif event_data['type'] == "WatchEvent"
      highlight = self.watch_event_to_text(event_data, highlight)
    elsif event_data['type'] == "PullRequestEvent"
      highlight = self.pr_event_to_text(event_data, highlight)
    end
    highlight
  end

  def self.pr_comment_event_to_text(event_data, highlight)
    if event_data['action'] == "created"
      commenter = event_data['sender']['login']
      highlight['label'] = "@#{commenter} commented on a PR in #{event_data['repo']['name']}"
      highlight['score'] = 0.6
      highlight['content'] = "#{event_data['comment']['body']}"
      highlight['category'] = "github PRcomment"
      highlight['actors'] = [commenter]
      highlight['upsert_key'] = "GH-COMMENT-PR-#{event_data['created_at']}-#{event_data['repo']['name']}"
    end
  end

  def self.issue_comment_event_to_text(event_data, highlight)
    commenter = event_data['actor']['login']
    comment = event_data['payload']['comment']['body']
    highlight['label'] = "@#{commenter} commented on #{event_data['repo']['name']}"
    highlight['score'] = 0.7
    highlight['content'] = comment
    highlight['category'] = "github CommentEvent"
    highlight['actors'] = [commenter]
    highlight['upsert_key'] = "GH-COMMENT-#{event_data['created_at']}-#{event_data['repo']}"
    highlight
  end

  def self.push_event_to_text(event_data, highlight)
    if event_data['payload']['commits'].last['message'][0,5] != "Merge"
      pusher = event_data['actor']['login']
      highlight['label'] = "@#{pusher} pushed directly to #{event_data['repo']['name']}"
      highlight['score'] = 0.8
      highlight['content'] = "#{event_data['payload']['commits'].last['message']}"
      highlight['category '] = "github PushEvent"
      highlight['upsert_key'] = "GH-PUSH-#{event_data['payload']['head']}"
      highlight['actors'] = [pusher]
      highlight
    end
  end

  def self.watch_event_to_text(event_data, highlight)
    if event_data['payload']['action'] == "started"
      watcher = event_data['actor']['login']
      highlight['upsert_key'] = "GH-WATCH-#{watcher}-#{event_data['repo']}"
      highlight['actors'] = [watcher]
      highlight['content'] = "@#{watcher} started watching the #{event_data['repo']['name']} repo"
      highlight['category'] = "github WatchEvent"
      highlight['score'] = 0.2
      highlight['label'] = "More people following #{event_data['repo']['name']}"
      highlight
    end
  end

  def self.fork_event_to_text(event_data, highlight)
    forker = event_data['actor']
    repo = event_data['repo']['name']
    highlight['upsert_key'] = "GH-FORK-#{forker}-#{repo}-#{event_data['created_at']}"
    highlight['actors'] = [forker]
    highlight['content'] = "@#{forker} forked #{repo}"
    highlight['category'] = 'github ForkEvent'
    highlight['score'] = 1.0
    highlight['label'] = ""
    highlight
  end

  def self.pr_event_to_text(event_data, highlight)
    repo_name = event_data['repo']['name']
    pr_number = event_data['payload']['pull_request']['number']
    pr_title = event_data['payload']['pull_request']['title']
    actor = event_data['actor']['login']
    highlight['upsert_key'] = "GH-PR-#{repo_name}-#{pr_number}"
    highlight['actors'] = [actor]
    highlight['category'] = "github PRevent"
    highlight['score'] = 1.0

    if event_data['payload']['action'] == "closed"
      if event_data['payload']['pull_request'].has_key?('merge_commit_sha')
        highlight['content'] = "@#{actor} merged #{pr_title} on #{repo_name}"
        highlight['label'] = "PR merged on #{repo_name}"
      else
        highlight['content'] = "@#{actor} closed #{pr_title} on #{repo_name}"
        highlight['label'] = "PR closed on #{repo_name}"
      end
    elsif event_data['payload']['action'] == "opened"
      highlight['content'] = "@#{actor} opened PR '#{pr_title}' on #{repo_name}"
      highlight['label'] = "PR opened on #{repo_name}"
    end
    highlight
  end
end
