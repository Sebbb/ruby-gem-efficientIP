#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'
Bundler.require(:default, :development)

require_relative './lib/solid_server'

IRB.start
