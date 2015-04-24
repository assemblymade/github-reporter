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
    uri = URI(url)
    res = Net::HTTP.post_form(uri, data)
    return res
  end

  

end
