class Hooks

  def self.add_webhook(owner, repo_name)
    username = ENV['GITHUB_AUTH_TOKEN']
    password = "x-oauth-basic"

    url = "https://api.github.com/repos/#{owner}/#{repo_name}/hooks"
    data = {}
    data['name'] = "web"
    data['active'] = "true"
    data['events'] = [ "*" ]
    data['config'] = {}
    data['config']['url'] = 'http://githubreporter.herokuapp.com/activity'
    data['config']['content_type'] = 'json'
    puts url
    puts data
    Remote.plain_post(url, data, username, password)
  end
end
