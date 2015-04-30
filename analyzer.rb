class Analyzer
  require_relative 'githubber'
  def self.commit_messages(owner, repo_name, history_length=nil)
    if history_length.nil?
      history_length = 86400*365*100
    end
    r = Githubber.commit_history(history_length, repo_name, owner)
    r['history'].map{|q| q['message']}
  end

  def self.keywordize(sentence)
    sentence.gsub(",","").gsub("'","").split(" ")
  end

end
