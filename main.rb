class Main
  require_relative 'githubber'
  require_relative 'text'

  def self.present_highlights(user, repo_name, history_length_in_days)
    a = Githubber.highlights(user, repo_name, history_length_in_days * 86400)
    return Text.text_from_highlights(a)
  end
end
