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
    elsif event_data['category'] == "IssueCommentEvent" or event_data['category'] == "PullRequestReviewCommentEvent"
      highlight = self.issue_comment_event_to_text(event_data, highlight)
    elsif event_data['category'] == "ForkEvent"
      highlight = self.fork_event_to_text(event_data, highlight)
    elsif event_data['category'] == "WatchEvent"
      highlight = self.watch_event_to_text(event_data, highlight)
    elsif event_data['category'] == "MemberEvent"
      highlight = self.member_event_to_text(event_data, highlight)
    end
    highlight
  end

  def self.pr_comment_event_to_text(event_data, highlight)
    if event_data['action'] == "created"
      commenter = event_data['sender']['login']
      highlight['label'] = "#{commenter} commented on a PR in #{event_data['repo']['name']}"
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
    highlight['label'] = "#{commenter} commented on #{event_data['repo']['name']}"
    highlight['score'] = 0.7
    highlight['content'] = comment
    highlight['category'] = "github CommentEvent"
    highlight['actors'] = [commenter]
    highlight['upsert_key'] = "GH-COMMENT-#{event_data['created_at']}-#{event_data['repo']}"
    highlight
  end

  def self.push_event_to_text(event_data, highlight)
    pusher = event_data['actor']['login']
    highlight['label'] = "#{pusher} pushed directly to #{event_data['repo']['name']}"
    highlight['score'] = 0.8
    highlight['content'] = "#{event_data['commits'].last['message']}"
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
      highlight['content'] = "#{watcher} started watching the #{event_data['repository']['name']} repo"
      highlight['category'] = "github WatchEvent"
      highlight['score'] = 0.2
      highlight['label'] = "More people following #{event_data['repo']}"
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
    highlight['label'] = "#{repo} forked!"
    highlight
  end

  def self.member_event_to_text(event_data, highlight)
    if event_data['action'] == "added"
      repo_name = event_data['repository']['name']
      user = event_data['member']['login']
      highlight['upsert_key'] = "GH-#{}"
      highlight['actors'] = [user]
      highlight['content'] = "#{user} is now a collaborator on #{repo_name}"
      highlight['category'] = "github NewMember"
      highlight['score'] = 0.8
      highlight['label'] = "New Collaborator on #{repo_name}"
      highlight
    end
  end

  def self.pr_event_to_text(event_data, highlight)
    highlight['upsert_key'] = "GH-"
    highlight['actors'] = []
    highlight['content'] = ""
    highlight['category'] = "github PushEvent"
    highlight['score'] = 1.0
    highlight['label'] = ""
    highlight
  end
end
