# frozen_string_literal: true

require 'rest-client'
require 'base64'
require 'json'
require 'erb'

module SOLIDserver
  class SOLIDserverError < StandardError
  end

  class SOLIDserver
    SERVICES = { 'ip_site_add' => 'This service allows to update an IP address Space.',
                 'ip_site_count' => 'This service returns the number of IP address Spaces matching optional condition(s).',
                 'ip_site_list' => 'This service returns a list of IP address Spaces matching optional condition(s).',
                 'ip_site_info' => 'This service returns information about a specific IP address Space.',
                 'ip_site_delete' => 'This service allows to delete a specific IP address Space.',
                 'ip_subnet_add' => 'This service allows to update an IPv4 Network of type Subnet or Block.',
                 'ip_block_subnet_count' => 'This service returns the number of IPv4 Networks matching optional condition(s).',
                 'ip_block_subnet_list' => 'This service returns a list of IPv4 Networks matching optional condition(s).',
                 'ip_block_subnet_info' => 'This service returns information about a specific IPv4 Network.',
                 'ip_subnet_delete' => 'This service allows to delete a specific IPv4 Network.',
                 'ip_find_free_subnet' => 'This service allows to retrieve a list of available IPv4 Networks matching optional condition(s).',
                 'ip6_subnet6_add' => 'This service allows to update an IPv6 Network of type Subnet or Block.',
                 'ip6_block6_subnet6_count' => 'This service returns the number of IPv6 Networks matching optional condition(s).',
                 'ip6_block6_subnet6_list' => 'This service returns a list of IPv6 Networks matching optional condition(s).',
                 'ip6_block6_subnet6_info' => 'This service returns information about a specific IPv6 Network.',
                 'ip6_subnet6_delete' => 'This service allows to delete a specific IPv6 Network.',
                 'ip6_find_free_subnet6' => 'This service allows to retrieve a list of available IPv6 Networks matching optional condition(s).',
                 'ip_pool_add' => 'This service allows to update an IPv4 Address Pool.',
                 'ip_pool_count' => 'This service returns the number of IPv4 Address Pools matching optional condition(s).',
                 'ip_pool_list' => 'This service returns a list of IPv4 Address Pools matching optional condition(s).',
                 'ip_pool_info' => 'This service returns information about a specific IPv4 Address Pool.',
                 'ip_pool_delete' => 'This service allows to delete a specific IPv4 Address Pool.',
                 'ip6_pool6_add' => 'This service allows to update an IPv6 Address Pool.',
                 'ip6_pool6_count' => 'This service returns the number of IPv6 Address Pools matching optional condition(s).',
                 'ip6_pool6_list' => 'This service returns a list of IPv6 Address Pools matching optional condition(s).',
                 'ip6_pool6_info' => 'This service returns information about a specific IPv6 Address Pool.',
                 'ip6_pool6_delete' => 'This service allows to delete a specific IPv6 Address Pool.',
                 'ip_add' => 'This service allows to update an IPv4 Address.',
                 'ip_address_count' => 'This service returns the number of IPv4 Addresses matching optional condition(s).',
                 'ip_address_list' => 'This service returns a list of IPv4 Addresses matching optional condition(s).',
                 'ip_address_info' => 'This service returns information about a specific IPv4 Address.',
                 'ip_delete' => 'This service allows to delete a specific IPv4 Address.',
                 'ip_find_free_address' => 'This service allows to retrieve a list of available IPv4 Addresses matching optional condition(s).',
                 'ip6_address6_add' => 'This service allows to update an IPv6 Address',
                 'ip6_address6_count' => 'This service returns the number of IPv6 Addresses matching optional condition(s).',
                 'ip6_address6_list' => 'This service returns a list of IPv6 Addresses matching optional condition(s).',
                 'ip6_address6_info' => 'This service returns information about a specific IPv6 Address.',
                 'ip6_address6_delete' => 'This service allows to delete a specific IPv6 Address.',
                 'ip6_find_free_address6' => 'This service allows to retrieve a list of available IPv6 Addresses matching optional condition(s).',
                 'ip_alias_add' => 'This service allows to associate an Alias of type A or CNAME to an IPv4 Address.',
                 'ip_alias_list' => "This service returns the list of an IPv4 Address' associated Aliases.",
                 'ip_alias_delete' => 'This service allows to remove an Alias associated to an IPv4 Address.',
                 'ip6_alias_add' => 'This service allows to associate an Alias of type A or CNAME to an IPv4 Address.',
                 'ip6_alias_list' => "This service returns the list of an IPv6 Address' associated Aliases.",
                 'ip6_alias_delete' => 'This service allows to remove an Alias associated to an IPv6 Address.',
                 'vlm_domain_add' => 'This service allows to update a VLAN Domain.',
                 'vlmdomain_count' => 'This service returns the number of VLAN Domains matching optional condition(s).',
                 'vlmdomain_list' => 'This service returns a list of VLAN Domains matching optional condition(s).',
                 'vlmdomain_info' => 'This service returns information about a specific VLAN Domain.',
                 'vlm_domain_delete' => 'This service allows to delete a specific VLAN Domain.',
                 'vlm_range_add' => 'This service allows to update a VLAN Range.',
                 'vlmrange_count' => 'This service returns the number of VLAN Ranges matching optional condition(s).',
                 'vlmrange_list' => 'This service returns a list of VLAN Domains matching optional condition(s).',
                 'vlmrange_info' => 'This service returns information about a specific VLAN Range.',
                 'vlm_range_delete' => 'This service allows to delete a specific VLAN Range.',
                 'vlm_vlan_add' => 'This service allows to update a VLAN.',
                 'vlmvlan_count' => 'This service returns the number of VLANs matching optional condition(s).',
                 'vlmvlan_list' => 'This service returns a list of VLANs matching optional condition(s).',
                 'vlmvlan_info' => 'This service returns information about a specific VLAN.',
                 'vlm_vlan_delete' => 'This service allows to delete a specific VLAN.' }.freeze
    class << self
      attr_accessor :api_endpoint

      def connect(*array, **hash)
        @api_endpoint = new(*array, **hash)
      end
    end

    SERVICES.each do |name, _description|
      define_method(name) do |method, *args|
        call(method, name, args)
      end
    end

    @url = ''
    @timeout  = 8
    @sslcheck = false
    @username = ''
    @password = ''

    # Inspector (Hide Sensitive Information)
    def inspect
      "#<#{self.class}:#{object_id} @url=\'#{@resturl}\' @sslcheck=#{@sslcheck} @timeout=#{@timeout}>"
    end

    # Constructor (Build the instance)
    # Requires:
    #   host: Targeted Host IP addresse or FQDN
    #   username: Username used to access the service
    #   password: Username associated password
    #   port: Listening http port (default 443)
    #   sslcheck: Verify SSL certificat (default false)
    #   timeout: HTTP query timeout (default 8)
    def initialize(host:, username:, password:, port: 443, sslcheck: true, timeout: 8)
      @resturl  = format('https://%s:%d/rest', host, port)
      @rpcurl   = format('https://%s:%d/rpc', host, port)
      @timeout  = timeout
      @sslcheck = sslcheck
      @username = Base64.strict_encode64(username)
      @password = Base64.strict_encode64(password)
    end

    # Generic REST call used to metaprogram all SOLIDserver available webservices
    # Requires:
    #   rest_method: HTTP verb called
    #   rest_service: API web service called
    #   args: array containing web service parameter within hashes
    # Programming Tips:
    #   * https://www.toptal.com/ruby/ruby-metaprogramming-cooler-than-it-sounds
    def call(rest_method, rest_service, args = {})
      rest_args = ''

      args.each do |_arg|
        args[0].each do |key, value|
          key = key.to_s.upcase if key.to_s == 'where' || key.to_s == 'orderby'

          rest_args += "#{key}=#{ERB::Util.url_encode(value.to_s)}&"
        end
      end

      # pp [rest_method, rest_service, args]

      begin
        RestClient::Request.execute(
          url: format('%s/%s?', (rest_service.match(/find_free/) ? @rpcurl : @resturl), rest_service) + rest_args,
          accept: 'application/json',
          method: rest_method,
          timeout: @timeout,
          verify_ssl: @sslcheck,
          headers: {
            'X-IPM-Username' => @username,
            'X-IPM-Password' => @password
          }
        )
      rescue RestClient::ExceptionWithResponse => e
        raise SOLIDserverError, "SOLIDserver REST call error: #{e.message}"
      end
    end

    # Documentation Generator
    # Requires:
    def doc
      buffer = ''
      descr_mapping = {}

      buffer += "## Available Methods:\n\n"
      buffer += "This GEM wraps the following SOLIDserver API calls, allowing you to interract with SOLIDserver DDI solution.\n"

      begin
        SERVICES.each do |service_name, service_description|
          buffer += "\n### Method - #{service_name}\n"
          rest_answer = RestClient::Request.execute(
            url: format('%s/%s', @resturl, service_name),
            accept: 'application/json',
            method: 'options',
            timeout: @timeout,
            verify_ssl: @sslcheck,
            headers: {
              'X-IPM-Username' => @username,
              'X-IPM-Password' => @password
            }
          )

          first_input = true
          first_output = true

          JSON.parse(rest_answer.body).each do |item|
            if item.key?('description')
              buffer += "Description\n\n"
              buffer += "\t#{service_description}\n"
            end

            if item.key?('mandatory_addition_params') && service_name.match(/_add$/)
              buffer += "\nMandatory Parameters\n\n"
              buffer += "\t#{item['mandatory_addition_params'].gsub('&&', '+').gsub('||', '|')}\n"
            end

            # if item.key?('mandatory_edition_params') && service_name.match(/_update$/)
            #   buffer += '\nMandatory Parameters\n\n'
            #   buffer += "\\t#{item['mandatory_edition_params'].gsub('&&', '+').gsub('||', '|')}\n"
            # end

            if item.key?('mandatory_params')
              buffer += "\nMandatory Parameters\n\n"
              buffer += "\t#{item['mandatory_params'].gsub('&&', '+').gsub('||', '|')}\n"
            end

            if item.key?('param_type')
              if item['param_type'] == 'in'
                if first_input == true
                  buffer += "\nAvailable Input Parameters:\n\n"
                  first_input = false
                end

                case item['name']
                when 'WHERE'
                  buffer += "\t* where - Can be used to filter the result using any output field in an SQL fashion.\n"
                when 'ORDERBY'
                  buffer += "\t* orderby - Can be used to order the result using any output field in an SQL fashion.\n"
                else
                  descr_key = service_name[/^(ip|vlm|dns)/]
                  descr_mapping["#{descr_key}_#{item['name']}"] = item['descr'] if item.key?('descr')
                  unless item.key?('descr') && item['name'].match(/^no_usertracking/)
                    buffer += "\t* #{item['name']}#{item.key?('descr') ? " - #{item['descr']}" : ''}\n"
                  end
                end
              else
                if first_output == true
                  buffer += "\nAvailable Output Fields:\n\n"
                  first_output = false
                end

                descr_key = service_name[/^(ip|vlm|dns)/]

                if item.key?('descr')
                  descr_mapping["#{descr_key}_#{item['name']}"] = item['descr']
                elsif descr_mapping.key?("#{descr_key}_#{item['name']}")
                  item['descr'] = descr_mapping["#{descr_key}_#{item['name']}"]
                end
                buffer += "\t* #{item['name']}#{item.key?('descr') ? " - #{item['descr']}" : ''}\n"
              end
            end
          end
        end

        buffer
      rescue RestClient::ExceptionWithResponse => e
        raise SOLIDserverError, "SOLIDserver REST call error: #{e.message}"
      end
    end
  end
end
