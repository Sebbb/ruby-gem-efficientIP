# frozen_string_literal: true

require 'rest-client'
require 'base64'
require 'json'
require 'erb'

# Extend Net::HTTPHeader to comply with case sensitive headers
module Net
  module HTTPHeader
    def capitalize(name)
      case name.downcase
      when 'x-ipm-username'
        'X-IPM-Username'
      when 'x-ipm-password'
        'X-IPM-Password'
      else
        name.to_s.split(/-/).map(&:capitalize).join('-')
      end
    end

    private :capitalize
  end
end

require_relative 'solid_server/solid_server'
require_relative 'ip_subnet/ip_subnet'
