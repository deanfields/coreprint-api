require "coreprint/version"
require "coreprint/api_resource"
require "coreprint/list_resource"
require "coreprint/account"
require "coreprint/basket"
require "coreprint/address"
require "coreprint/product"
require "coreprint/order"
require "coreprint/dam"

require "httparty"
require "json"

module Coreprint
  CP_TEST = false

  def self.log(string)
    if defined? Rails
      Rails.logger.debug string
    else
      puts string
    end
  end

  def self.server(test = false)
    server = test ? "test-ws" : "ws"
    "http://www.coreprint.net/#{server}/jsonfactory/"
  end

  def self.request(method, service, account, params = {}, payload = nil)
    #method = method.to_s.downcase.to_sym
    credentials = account.credentials
    url = CorePrint.server(CP_TEST)

    query = {
      :key => credentials[:key],
      :service => service
    }
    query.merge! params

    options = {
      :query => query,
      :basic_auth => {
        :username => credentials[:username],
        :password => credentials[:password]
      }
    }

    unless method == :stream
      options[:body] = payload.to_json
      options[:headers] = { 'Content-Type' => 'text/html' }
    else
      options[:body_stream] = payload
      options[:headers] = { 'Transfer-Encoding' => 'chunked', 'Content-Type' => 'text/html' }
    end

    CorePrint.log url
    CorePrint.log options
    CorePrint.log payload.to_json

    #begin
      case method
      when :get
        CorePrint.log "CorePrint (#{service}) [GET]: #{query.to_query}"
        response = HTTParty.get(url, options)
      when :post
        CorePrint.log "CorePrint (#{service}) [POST]: #{payload.to_json} #{query.to_query}"
        response = HTTParty.post(url, options)
      when :put
        CorePrint.log "CorePrint (#{service}) [PUT]: #{payload.to_json}"
        response = HTTParty.put(url, options)
      when :stream
        CorePrint.log "CorePrint (#{service}) [STREAM]: #{query.to_query} #{payload.size}"
        response = HTTParty.post(url, options)
      else
        CorePrint.log "CorePrint (#{service}) method #{method} not found"
        response = nil
      end
    #rescue
    #  response = false
    #end

    CorePrint.log "Received response code #{response.code}"

    if response.code == 404
      return {}
    end

    if response
      if response.body && response.body.is_a?(String)
        CorePrint.log "CorePrint (#{service}) Received: #{response.body.slice(0, 1000)}"
      end

      return parse(response.body)
    else
      return {}
    end
  end

  def self.parse(response)
    return {} if !response.present?

    begin
      response = JSON.parse(response)

      return convert_array(response)
    rescue
      return response
    end
  end

  def self.is_json?(str)
    begin
      !!JSON.parse(str)
    rescue
      false
    end
  end

  def self.convert_array(hash)
    arr = []
    hash.each { |k, v| arr << v.symbolize_keys }

    if arr.length > 1
      return arr
    else
      return arr[0]
    end
  end
end
