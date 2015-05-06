class ActivityController < ApplicationController
  respond_to :json, :html

  def index
    puts "RECEIVED MESSAGE"
    puts params.keys()

    if params.has_key?("comment")
      name = params['comment']['repository']['name']
      owner = params['comment']['repository']['owner']['login']
      changelog = Repo.changelog_from_repo(owner, name)
      text_package = Text.

      #GithubMain.send_highlight(text_package, changelog)
    end


    render json: {}
  end

  def welcome
    render json: {:message => "hi there"}
  end

end
