namespace :main do
  desc "Push Assembly highlights to Titan"
  task :push_highlights do
    time_length = 0.3s #days

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

    #Main.push_all('bitcoin', 'bitcoin', time_length, 'bitcoin')
    #Main.push_all('rails', 'rails', time_length, 'rails')

  end

  desc 'Delete all existing changelog items'
  task :delete_all do
    Main.delete_all
  end

  desc 'Rebuild'
  task :rebuild do
    Main.delete_all
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
