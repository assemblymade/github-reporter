require 'net/http'

class Remote
  def self.get(url=url, params=nil)
    uri = URI(url)
    if params
      uri.query = URI.encode_www_form(params)
    end
    res = Net::HTTP.get(uri)
    return res
  end

  def self.post(url, data)
    data = data.to_json
    uri = URI(url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = false
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth('githubber', '7ef5a8668f98a1efc2d17105eb98eab3fb0bb53010341dfba468f6c5b33fb8ff')
    req.body = data
    res = https.request(req)
    puts "Response #{res.code} #{res.message}: #{res.body}"

    return res
  end





end
