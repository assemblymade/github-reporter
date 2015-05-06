class Remote
  def self.get(url=url, params=nil)
    uri = URI(url)
    if params
      uri.query = URI.encode_www_form(params)
    end
    res = Net::HTTP.get(uri)
    return res
  end

  def self.delete(url)
    uri = URI(url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = false
    req = Net::HTTP::Delete.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    reporter_name = ENV['REPORTER_NAME']
    reporter_password = ENV['REPORTER_PASSWORD']
    req.basic_auth(reporter_name, reporter_password)
    res = https.request(req)
    puts "Response #{res.code} #{res.message}: #{res.body}"
    return res
  end

  def self.plain_post(url, data, username=nil, password=nil)
    data = data.to_json
    uri = URI(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    if username
      req.basic_auth(username, password)
    end
    req.body = data
    res = https.request(req)
    puts "Response #{res.code} #{res.message}: #{res.body}"
    return res
  end

  def self.post(url, data)
    data = data.to_json
    uri = URI(url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = false
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    reporter_name = ENV['REPORTER_NAME']
    reporter_password = ENV['REPORTER_PASSWORD']
    req.basic_auth(reporter_name, reporter_password)
    req.body = data
    res = https.request(req)
    puts "Response #{res.code} #{res.message}: #{res.body}"

    return res
  end
end
