# frozen_string_literal: true

module SOLIDserver
  class IpSubnet
    attr_reader :fields

    FIELDS = {
      name: 'subnet${PROTOCOL_IDENTIFIER}_name',
      site_name: 'site_name'
    }.freeze

    class << self
      def find(where:, limit: 20, api_endpoint: SOLIDserver.api_endpoint)
        result = api_endpoint.public_send(
          "ip#{self::PROTOCOL_IDENTIFIER}_block#{self::PROTOCOL_IDENTIFIER}_subnet#{self::PROTOCOL_IDENTIFIER}_list", 'get', {
            limit: limit, where: where
          }
        )
        return [] if result.body.empty?

        JSON.parse(result.body).map do |fields|
          new(fields: fields)
        end
      end
    end

    def initialize(fields: {})
      raise if instance_of?(IpSubnet)
      raise unless fields.is_a?(Hash)

      @fields = fields
    end

    def subnet_class_parameters
      URI.decode_www_form(fields["subnet#{self.class::PROTOCOL_IDENTIFIER}_class_parameters"]).transform_keys(&:to_sym)
    end

    def children
      self.class.find(where: "parent_subnet_id = #{fields['subnet_id']}")
    end

    def parent
      self.class.find(where: "subnet_id = #{fields['parent_subnet_id']}", limit: 1).first
    end
  end

  class IpSubnet4 < IpSubnet
    PROTOCOL_IDENTIFIER = ''

    def ipaddr
      network_bits = fields['subnet_size'] == '0' ? 0 : 32 - Math.log2(fields['subnet_size'].to_i).to_i
      IPAddr.new(fields['start_ip_addr'].to_i(16), Socket::AF_INET).mask(network_bits)
    end
  end

  class IpSubnet6 < IpSubnet
    PROTOCOL_IDENTIFIER = '6'

    def ipaddr
      IPAddr.new(fields['start_ip6_addr'].to_i(16), Socket::AF_INET6).mask(fields['subnet6_prefix'])
    end
  end
end
