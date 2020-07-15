# -*- coding: utf-8 -*-
require "net/http"
require "uri"
require "json"
require "digest"
require "base64"
require 'zlib'
require 'stringio'
require 'openssl'

# Linkhub API Base Class
class Linkhub
  attr_accessor :_linkID, :_secretKey

  LINKHUB_APIVersion = "1.0"
  LINKHUB_ServiceURL = "https://auth.linkhub.co.kr"
  LINKHUB_ServiceURL_GA = "https://ga-auth.linkhub.co.kr"

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
  def getSessionToken(serviceid, accessid, scope, forwardip="",useStaticIP=false)
    uri = URI( (useStaticIP ? LINKHUB_ServiceURL_GA : LINKHUB_ServiceURL) + "/" + serviceid + "/Token")

    postData = {:access_id => accessid, :scope => scope}.to_json

    apiServerTime = getTime(useStaticIP)

    hmacTarget = "POST\n"
    hmacTarget += Base64.strict_encode64(Digest::MD5.digest(postData)) + "\n"
    hmacTarget += apiServerTime + "\n"

    if forwardip != ""
      hmacTarget += forwardip + "\n"
    end

    hmacTarget += LINKHUB_APIVersion + "\n"
    hmacTarget += "/" + serviceid + "/Token"

    key = Base64.decode64(@_secretKey)

    data = hmacTarget
    digest = OpenSSL::Digest.new("sha1")
    hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, key, data))

    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "LINKHUB " + @_linkID + " " + hmac,
      "Accept-Encoding" => "gzip,deflate",
      "x-lh-date" => apiServerTime,
      "x-lh-version" => LINKHUB_APIVersion
    }

    if forwardip != ""
      headers.store("x-lh-forwarded", forwardip)
    end

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    res = https.post(uri.path, postData, headers)

    begin
      gz = Zlib::GzipReader.new(StringIO.new(res.body.to_s))
      uncompressed_string = gz.read
    rescue Zlib::Error => le
      uncompressed_string = res.body
    end

    if res.code == "200"
      JSON.parse(uncompressed_string)
    else
      raise LinkhubException.new(JSON.parse(uncompressed_string)["code"],
        JSON.parse(uncompressed_string)["message"])
    end
  end # end of getToken


  # Get API Server UTC Time
  def getTime(useStaticIP=false)
    uri = URI((useStaticIP ? LINKHUB_ServiceURL_GA : LINKHUB_ServiceURL) + "/Time")
    
    res = Net::HTTP.get_response(uri)

    if res.code == "200"
      res.body
    else
      raise LinkhubException.new(-99999999,
        "failed get Time from Linkhub API server")
    end
  end

  # 파트너 포인트 충전 URL - 2017/08/29 추가
  def getPartnerURL(bearerToken, serviceID, togo, useStaticIP=false)
    uri = URI((useStaticIP ? LINKHUB_ServiceURL_GA : LINKHUB_ServiceURL) + "/" + serviceID + "/URL?TG=" + togo)

    headers = {
      "Authorization" => "Bearer " + bearerToken,
    }

    https = Net::HTTP.new(uri.host, 443)
    https.use_ssl = true
    Net::HTTP::Post.new(uri)

    res = https.get(uri.request_uri, headers)

    if res.code == "200"
      JSON.parse(res.body)["url"]
    else
      raise LinkhubException.new(JSON.parse(res.body)["code"],
        JSON.parse(res.body)["message"])
    end
  end

  # Get Popbill member remain point
  def getBalance(bearerToken, serviceID, useStaticIP=false)
    uri = URI((useStaticIP ? LINKHUB_ServiceURL_GA : LINKHUB_ServiceURL) + "/" + serviceID + "/Point")

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
  def getPartnerBalance(bearerToken, serviceID, useStaticIP)
    uri = URI( (useStaticIP ? LINKHUB_ServiceURL_GA : LINKHUB_ServiceURL) + "/" + serviceID + "/PartnerPoint")

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
