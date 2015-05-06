class ActivityController < ApplicationController
  respond_to :json, :html

  def index
    puts "RECEIVED MESSAGE"
    puts params
  end

  def welcome
    render json: {:message => "hi there"}
  end

end
