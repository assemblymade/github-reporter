require_relative 'main'

namespace :main do
  desc "Push Assembly highlights to Titan"
  task :push_pr_highlights => :environment do
    time_length = 5 #days

    Main.push_all('assemblymade', 'meta', time_length)

  end
end
