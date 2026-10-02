# frozen_string_literal: true

module SOLIDserver
  class IpAddress
    attr_reader :fields

    FIELDS = {
      name: 'name',
      id: 'ip${PROTOCOL_IDENTIFIER}_id',
    }.freeze

    class << self
      def find(where:, limit: 20, api_endpoint: SOLIDserver.api_endpoint)
        result = api_endpoint.public_send(
          "ip_address#{self::PROTOCOL_IDENTIFIER}_list",
          'get', { limit: limit, where: where }
        )
        return [] if result.body.empty?

        JSON.parse(result.body).filter_map do |fields|
          next if fields['type'] == 'free'

          new(fields: fields)
        end
      end

      def find_by_name(name, limit: 20, api_endpoint: SOLIDserver.api_endpoint, site:)
        search_query = "LOWER(name) LIKE LOWER('#{name}') AND site_name='#{site}'"
        find(where: search_query, limit: limit, api_endpoint: api_endpoint)
      end
    end

    def ip_class_parameters
      Hash[URI.decode_www_form(fields["ip#{self.class::PROTOCOL_IDENTIFIER}_class_parameters"])].transform_keys(&:to_sym)
    end

    def initialize(fields: {})
      raise if instance_of?(IpAddress)
      raise unless fields.is_a?(Hash)

      @fields = fields
    end

  end

  class IpAddress4 < IpAddress
    PROTOCOL_IDENTIFIER = ''
    FIELDS.each do |k, v|
      field_name = v.gsub(/\$\{([^}]+)\}/) do
        eval(Regexp.last_match(1))
      end

      define_method k do
        fields[field_name]
      end
    end

    class << self
      def get_by_ipaddr(ipaddr, site:)
        ipaddr_hex = ipv4_dottedquad_to_hex(ipaddr)
        search_query4 = "site_name='#{site}' AND ip_addr = '#{ipaddr_hex}'"
        find(where: search_query4, limit: 1).first
      end

      def ipv4_dottedquad_to_hex(str)
        str.split('.').map { |octet| octet.to_i.to_s(16).rjust(2, '0') }.join
      end
    end

    def ipaddr
      IPAddr.new(fields['ip_addr'].to_i(16), Socket::AF_INET)
    end

    # has a completely different name for v6
    def delete(api_endpoint: SOLIDserver.api_endpoint)
      result = api_endpoint.public_send(
        "ip_delete",
        'delete', { "ip_id" => id }
      )
    end
  end

  class IpAddress6 < IpAddress
    PROTOCOL_IDENTIFIER = '6'

    def ipaddr
      IPAddr.new(fields['ip6_addr'].to_i(16), Socket::AF_INET6)
    end
  end
end
