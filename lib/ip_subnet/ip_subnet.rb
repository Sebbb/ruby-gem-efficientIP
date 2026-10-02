# frozen_string_literal: true

module SOLIDserver
  class IpSubnet
    attr_reader :fields

    FIELDS = {
      name: 'subnet${PROTOCOL_IDENTIFIER}_name',
      site_name: 'site_name'
    }.freeze

    class << self
      def find(where:, limit: 20, api_endpoint: SOLIDserver.api_endpoint, orderby: nil, tag: nil)
        result = api_endpoint.public_send(
          "ip#{self::PROTOCOL_IDENTIFIER}_block#{self::PROTOCOL_IDENTIFIER}_subnet#{self::PROTOCOL_IDENTIFIER}_list",
          'get', { limit: limit, where: where, orderby: orderby }.merge(tag ? { TAGS: tag } : {})
        )
        return [] if result.body.empty?

        JSON.parse(result.body).map do |fields|
          new(fields: fields)
        end
      end

      def list_all_subnets_with_tag(site:, tag:, limit: 5000)
        search_query4 = "site_name='#{site}' AND (tag_network_#{tag} <> '')"
        search_query6 = "site_name='#{site}' AND (tag_network6_#{tag} <> '')"
        IpSubnet4.find(where: search_query4, limit: limit, tag: "network.#{tag}") +
          IpSubnet6.find(where: search_query6, limit: limit, tag: "network6.#{tag}")
      end

      def ipv4_to_hex(str)
        str.split('.').map { |octet| octet.to_i.to_s(16).rjust(2, '0') }.join
      end

      def ipv6_to_hex(str)
        IPAddr.new(str).to_string.gsub(':', '')
      end
    end

    def initialize(fields: {})
      raise if instance_of?(IpSubnet)
      raise unless fields.is_a?(Hash)

      @fields = fields
    end

    def subnet_class_parameters
      Hash[URI.decode_www_form(fields["subnet#{self.class::PROTOCOL_IDENTIFIER}_class_parameters"])].transform_keys(&:to_sym)
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

    FIELDS.each do |k, v|
      field_name = v.gsub(/\$\{([^}]+)\}/) do
        eval(Regexp.last_match(1))
      end

      define_method k do
        fields[field_name]
      end
    end

    class << self
      def get_subnet_for_ip(ip, site:, is_terminal: true)
        get_subnets_for_ip(ip, site: site, is_terminal: is_terminal, limit: 1).first
      end

      def get_subnets_for_ip(ip, site:, is_terminal:, limit: 20)
        ipaddr = SolidServerIPAddr.new(ip)
        start_ip = ipv4_to_hex(ipaddr.net_addr.to_s).to_i(16)
        end_ip = ipv4_to_hex(ipaddr.broadcast_addr.to_s).to_i(16)
        query = "site_name='#{site}' AND (cast(('0x'||start_ip_addr) as decimal) <= #{start_ip}) AND (cast(('0x'||end_ip_addr) as decimal) >= #{end_ip})"
        query += " AND is_terminal = '1'" if is_terminal

        find(where: query, limit: limit, orderby: 'cast(subnet_size as int) asc')
      end

      def find_subnets(subnets, site:, is_terminal: false)
        [].tap do |all_results|
          subnets.each_slice(40) do |batch|
            conditions = batch.map do |cidr|
              ipaddr = SolidServerIPAddr.new(cidr)
              start_ip = ipv4_to_hex(ipaddr.net_addr.to_s).to_i(16)
              end_ip = ipv4_to_hex(ipaddr.broadcast_addr.to_s).to_i(16)
              "(cast(('0x'||start_ip_addr) as decimal) = #{start_ip} AND cast(('0x'||end_ip_addr) as decimal) = #{end_ip})"
            end.join(" OR ")

            query = "site_name='#{site}' AND (#{conditions})"
            query += " AND is_terminal = '1'" if is_terminal

            all_results.concat(find(where: query, limit: batch.length))
          end
        end
      end

      def find_subnet(cidr, site:, is_terminal: false)
        find_subnets([cidr], site: site, is_terminal: is_terminal).first
      end
    end

    def ipaddr
      network_bits = fields['subnet_size'] == '0' ? 0 : 32 - Math.log2(fields['subnet_size'].to_i).to_i
      IPAddr.new(fields['start_ip_addr'].to_i(16), Socket::AF_INET).mask(network_bits)
    end
  end

  class IpSubnet6 < IpSubnet
    PROTOCOL_IDENTIFIER = '6'

    FIELDS.each do |k, v|
      field_name = v.gsub(/\$\{([^}]+)\}/) do
        eval(Regexp.last_match(1))
      end

      define_method k do
        fields[field_name]
      end
    end

    class << self
      def get_subnet_for_ip(ipaddr, site:, is_terminal: true)
        int_ip = ipv6_to_hex(ipaddr).to_i(16)
        query = "site_name='#{site}' AND (cast(('0x'||start_ip6_addr) as decimal) <= #{int_ip}) AND (cast(('0x'||end_ip6_addr) as decimal) >= #{int_ip})"
        query += " AND is_terminal = '1'" if is_terminal

        find(where: query, limit: 1, orderby: 'cast(subnet6_prefix as int) desc').first
      end
    end

    def ipaddr
      IPAddr.new(fields['start_ip6_addr'].to_i(16), Socket::AF_INET6).mask(fields['subnet6_prefix'])
    end
  end
end
