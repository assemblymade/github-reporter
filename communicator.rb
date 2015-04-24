class Communicator
  require_relative 'text'
  require_relative 'githubber'
  require_relative 'remote'

  def create_send_highlight(owner, repo_name, time_length)
    h = Githubber.highlights(owner, repo_name, time_length)
    d = Text.text_from_highlights(h)

    org_id = "8ace1942-bfc3-4d2e-95dc-8882785cf7f4"
    url = "http://titan-api.herokuapp.com/orgs/#{org_id}/highlights"

    d['users'].each do |a|
      puts Remote.post(url, a)
    end

    d['prs'].each do |a|
      puts Remote.post(url, a)
    end

    d['files'].each do |a|
      puts Remote.post(url, a)
    end

    d
  end

end
