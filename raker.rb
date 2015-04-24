require_relative 'main'

namespace :main do
  desc "Push PR highlights to Titan"
  task :push_pr_highlights => :environment do
    time_length = 3 #days

    Main.push_pr_highlights('assemblymade', 'meta', time_length)
  

  end
end
