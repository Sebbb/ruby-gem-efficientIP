# EfficientIP SOLIDserver Gem

This Gem allows to easily interact with [SOLIDserver](http://www.efficientip.com/products/solidserver/)'s REST API.
It allows managing all IPAM objects through CRUD operations.

This GEM is compatible with [SOLIDserver](http://www.efficientip.com/products/solidserver/) version 6.0.0 and higher.

It can be easily used within :
* Ruby code - See [rubygems.org](https://rubygems.org/)
* [CHEF](https://www.chef.io/chef/) - See [this blog post](https://blog.chef.io/2009/06/01/cool-chef-tricks-install-and-use-rubygems-in-a-chef-run/)
* [Puppet](https://puppet.com) - See [the puppet documentation](https://docs.puppet.com/puppetserver/latest/gems.html#installing-gems-for-use-with-development)

# Install

Add a dependency in your application's Gemfile :

```
	gem 'SOLIDserver' :git => "git://github.com/Sebbb/ruby-gem-efficientIP.git"

```

Then execute :

```
	$ bundle install
```

Or install it yourself as:

```
	$ gem install SOLIDserver
```

# Usage
## Using the SOLIDserver object
Before making method calls, you need to instance a SOLIDserver object using your credentials.

```
	require "SOLIDserver"

	SOLIDserver::SOLIDserver.connect(host: '<SOLIDserver IP address>', username: '<login>', password: '<password>')
```

Once this operation completed, you are able to interact with the IPAM's objects directly using any supported method. You need to specify the desired method (get/put/post/delete) as well.

Each method return (except the doc one) retrun a REST object containing a json body and a return code.

```
  SOLIDserver::SOLIDserver.api_endpoint.ip_address_list('get', limit: 5).body
```

## Mandatory Parameters
Some methods require specific parameters combination. These parameters are listed in the method list below in the following format :

```
	(<required parameter #1> + (<required parameter #2>) | <required parameter #3>)
```

This means that you need to provide :
```
	<required parameter #1> and <required parameter #2>
```
or
```
	<required parameter #1> and <required parameter #3>
```

This parameters must be provided through a hash :

```
	puts sdsapi.ip_site_list(limit: 128, offset: 0, where: "site_name like '%test%'").body
```

## Filtering the result
Some methods allow to filter their output result using a WHERE parameter.

This clause can be applied on any output field combination using an SQL ANSI style clause.

## Available Methods

After connecting, a list of all available methods and their parameters can be retreived with

```
  puts SOLIDserver::SOLIDserver.api_endpoint.doc
```
