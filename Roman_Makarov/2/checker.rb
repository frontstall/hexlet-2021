#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'csv'
require 'net/http'
require 'benchmark'

class Optparser
  def parse(args)
    @options = { no_subdomains: false, filter: nil, exclude_solutions: false, path_to_file: nil }
    @args = OptionParser.new do |opts|
      opts.banner = 'Usage: checker.rb <path_to_file> [options]'

      opts.on('--no-subdomains', 'Ignore subdomains') { @options[:no_subdomains] = true }
      opts.on('--exclude-solutions', 'Ignore opensource') { @options[:exclude_solutions] = true }
      opts.on('--filter=WORD', 'Filter by specific word') { |word| @options[:filter] = word }

      opts.parse!(args)
    end
    @options[:path_to_file] = args.first
    @options
  end
end

class CSVParser
  def initialize(path_to_file, filter = nil)
    @path_to_file = path_to_file
    @filter = filter
  end

  def parse
    file_data = File.read(@path_to_file)
    CSV.parse(file_data).flatten
  end
end

parser = Optparser.new
options = parser.parse(ARGV)

urls = CSVParser.new('./fixture.csv').parse

class Ping
  def initialize(urls)
    @urls = urls
    @logs = []
    @stats = {
      total: 0,
      succeeded: 0,
      failed: 0,
      errors: 0
    }
  end

  def normalize(url)
    "http://#{url}"
  end

  def fetch(url)
    uri = URI(normalize(url))
    @stats[:total] += 1
    start_time = Time.now
    log = "#{url} - "
    begin
      response = Net::HTTP.get_response(uri)

      @stats[:succeeded] += 1 if response.code.start_with?('2') || response.code.start_with?('3')
      @stats[:failed] += 1 if response.code.start_with?('4') || response.code.start_with?('5')
      time = Time.now - start_time
      log << "#{response.code} (#{(time * 1000).to_i}ms)"
    rescue StandardError => e
      @stats[:errors] += 1
      log << "ERROR: (#{e.message})"
    end
    puts log
  end

  def fetch_all
    @urls.each { |url| fetch(url) }
    @stats
  end
end

ping = Ping.new(urls)
puts ping.fetch_all
