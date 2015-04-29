require_relative 'main'

namespace :main do
  desc "Push Assembly highlights to Titan"
  task :push_highlights do
    time_length = 3 #days

    repos = ['github-reporter',
            'trello-reporter',
            'slack-reporter',
            'titan-web',
            'titan-ios',
            'titan-api'
            ]
    repos.each do |r|
      Main.push_all('assemblymade', r, time_length, 'assembly')
    end
  end
end
