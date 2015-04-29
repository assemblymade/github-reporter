require_relative 'main'

namespace :main do
  desc "Push Assembly highlights to Titan"
  task :push_highlights do
    time_length = 7 #days

    Main.push_all('assemblymade', 'meta', time_length, 'assembly')
    Main.push_all('assemblymade', 'githubreporter', time_length, 'githubreporter')
  end
end
