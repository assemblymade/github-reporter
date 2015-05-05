namespace :github_main do
  desc "Push Assembly highlights to Titan"
  task :push_highlights  => :environment do
    time_length = 0.1 #days

    repos = ['github-reporter',
            'trello-reporter',
            'slack-reporter',
            'titan-web',
            'titan-ios',
            'titan-api'
            ]
    repos.each do |r|
      GithubMain.push_all('assemblymade', r, time_length, 'assembly')
    end

    GithubMain.push_all('assemblymade', 'coderwall', 0.1, 'coderwall')
    GithubMain.push_all('bitcoin', 'bitcoin', time_length, 'bitcoin')
    GithubMain.push_all('rails', 'rails', time_length, 'rails')

  end

  desc 'Delete all existing changelog items'
  task :delete_all => :environment do
    GithubMain.delete_all
  end

  desc 'Rebuild'
  task :rebuild => :environment do
    GithubMain.delete_all
    time_length = 3 #days
    repos = ['github-reporter',
            'trello-reporter',
            'slack-reporter',
            'titan-web',
            'titan-ios',
            'titan-api'
            ]
    repos.each do |r|
      GithubMain.push_all('assemblymade', r, time_length, 'assembly')
    end
    GithubMain.push_all('assemblymade', 'coderwall', 0.1, 'coderwall')
  end

end
