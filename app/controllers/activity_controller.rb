class ActivityController < ApplicationController
  respond_to :json

  def index
    puts "RECEIVED MESSAGE"
    puts params
  end
end
