class SearchesController < ApplicationController
  skip_before_action :authenticate_user
  
  def search
  end

  def create
  resp = Faraday.get("https://foursquare.com/oauth2/access_token") do |req|
    req.params['client_id'] = ENV['FOURSQUARE_CLIENT_ID']
    req.params['client_secret'] = ENV['FOURSQUARE_SECRET']
    req.params['grant_type'] = 'authorization_code'
    req.params['redirect_uri'] = "http://localhost:3000/auth"
    req.params['code'] = params[:code]
  end

  body = JSON.parse(resp.body)
  session[:token] = body["access_token"]
  redirect_to root_path
end

  def foursquare
    client_id = ENV['FOURSQUARE_CLIENT_ID']
    client_secret = ENV['FOURSQUARE_SECRET']

    @resp = Faraday.get 'https://api.foursquare.com/v2/venues/search' do |req|
      req.params['client_id'] = client_id
      req.params['client_secret'] = client_secret
      req.params['v'] = '20160201'
      req.params['near'] = params[:zipcode]
      req.params['query'] = 'coffee shop'
    end

    body = JSON.parse(@resp.body)

    if @resp.success?
      @venues = body["response"]["venues"]
    else
      @error = body["meta"]["errorDetail"]
    end
    render 'search'

    rescue Faraday::TimeoutError
      @error = "There was a timeout. Please try again."
      render 'search'
  end

  def friends
    resp = Faraday.get("https://api.foursquare.com/v2/users/self/friends") do |req|
      req.params['oauth_token'] = session[:token]
      # don't forget that pesky v param for versioning
      req.params['v'] = '20160201'
    end
    @friends = JSON.parse(resp.body)["response"]["friends"]["items"]
  end
end
