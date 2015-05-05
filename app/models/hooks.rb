class Hooks

  def self.add_webhook(owner, repo_name)
    url = "https://api.github.com/repos/#{owner}/#{repo_name}/hooks"
    data = {}
    data['name'] = "web"
    data['active'] = "true"
    data['events'] = [ "*" ]
    data['config'] = {
      url: 'http://githubreporter.herokuapp.com/activity',
      content_type: 'json'
      }
    Remote.plain_post(url, data)
  end
end



post "/repos/#{repo}/hooks",
    name: "web",
    active: "true",
    events: %w(push pull_request pull_request_review_comment issue_comment),
    config: {
      url: 'https://assembly.com/webhooks/github',
      content_type: 'json'
    }
