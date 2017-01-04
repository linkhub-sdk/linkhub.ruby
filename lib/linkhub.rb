# -*- coding: utf-8 -*-
require "net/http"
require "uri"
require "json"
require "digest"
require "base64"

# Linkhub API Base Class
class Linkhub
  attr_accessor :_linkID, :_secretKey

  LINKHUB_APIVersion = "1.0"
  LINKHUB_ServiceURL = "https://auth.linkhub.co.kr"

  # Generate Linkhub Class Singleton Instance
  class << self
    def instance(linkID, secretKey)
      @instance ||= new
      @instance._linkID = linkID
      @instance._secretKey = secretKey
      return @instance
    end
    private :new
  end

  # Get SessionToken for Bearer Token
  def getSessionToken(serviceid, accessid, scope)
    uri = URI(LINKHUB_ServiceURL + "/" + serviceid + "/Token")
    postData = {:access_id => accessid, :scope => scope}.to_json

    apiServerTime = getTime()

    hmacTarget = "POST\n"
    hmacTarget += Base64.strict_encode64(Digest::MD5.digest(postData)) + "\n"
    hmacTarget += apiServerTime + "\n"
    hmacTarget += LINKHUB_APIVersion + "\n"
    hmacTarget += "/" + serviceid + "/Token"

    key = Base64.decode64(@_secretKey)

    data = hmacTarget
    digest = OpenSSL::Digest.new("sha1")
    hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, key, data))

    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "LINKHUB " + @_linkID + " " + hmac,
      "Accept-Encoding" => "gzip,deflate",
      "x-lh-date" => apiServerTime,
      "x-lh-version" => LINKHUB_APIVersion
    }

    https = Net::HTTP.new(uri.host, 443)
    https.use_ssl = true
    Net::HTTP::Post.new(uri)

    res = https.post(uri.path, postData, headers)

    if res.code == "200"
      JSON.parse(res.body)
    else
      raise LinkhubException.new(JSON.parse(res.body)["code"],
        JSON.parse(res.body)["message"])
    end
  end # end of getToken


  # Get API Server UTC Time
  def getTime
    uri = URI(LINKHUB_ServiceURL + "/Time")
    res = Net::HTTP.get_response(uri)

    if res.code == "200"
      res.body
    else
      raise LinkhubException.new(-99999999,
        "failed get Time from Linkhub API server")
    end
  end

  # Get Popbill member remain point
  def getBalance(bearerToken, serviceID)
    uri = URI(LINKHUB_ServiceURL + "/" + serviceID + "/Point")

    headers = {
      "Authorization" => "Bearer " + bearerToken,
    }

    https = Net::HTTP.new(uri.host, 443)
    https.use_ssl = true
    Net::HTTP::Post.new(uri)

    res = https.get(uri.path, headers)

    if res.code == "200"
      JSON.parse(res.body)["remainPoint"]
    else
      raise LinkhubException.new(JSON.parse(res.body)["code"],
        JSON.parse(res.body)["message"])
    end
  end

  # Get Linkhub partner remain point
  def getPartnerBalance(bearerToken, serviceID)
    uri = URI(LINKHUB_ServiceURL + "/" + serviceID + "/PartnerPoint")

    headers = {
      "Authorization" => "Bearer " + bearerToken,
    }

    https = Net::HTTP.new(uri.host, 443)
    https.use_ssl = true
    Net::HTTP::Post.new(uri)

    res = https.get(uri.path, headers)

    if res.code == "200"
      JSON.parse(res.body)["remainPoint"]
    else
      raise LinkhubException.new(JSON.parse(res.body)["code"],
        JSON.parse(res.body)["message"])
    end
  end
end

# Linkhub API Exception class
class LinkhubException < StandardError
  attr_reader :code, :message
  def initialize(code, message)
    @code = code
    @message = message
  end
end
