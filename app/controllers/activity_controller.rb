class ActivityController < ApplicationController::Base
  respond_to :json
  
  def index
    puts "RECEIVED MESSAGE"
    puts params
  end
end
