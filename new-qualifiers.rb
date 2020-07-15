#!/bin/env ruby
# frozen_string_literal: true

# Check a Wikipedia scraper outfile against what's currently in
# Wikidata, creating wikibase-cli commands for any qualifiers to add.

require 'csv'
require 'pry'

require_relative 'lib/inputfile'

# TODO: sanity check the input
wikipedia_file = Pathname.new(ARGV.first) # output of scraper
wikidata_file = Pathname.new(ARGV.last) # `wd sparql term-members.sparql`

wikipedia = InputFile::CSV.new(wikipedia_file)
wikidata = InputFile::JSON.new(wikidata_file)

wptally = wikipedia.data.map { |r| r[:id] }.tally
wdtally = wikidata.data.map { |r| r[:id] }.tally
no_P39s = wptally.keys - wdtally.keys

wikipedia.data.each do |wp|
  # TODO: hoist this into InputFile#find
  matches = wikidata.find(wp[:id])
  matches = matches.select { |wd| wd[:P580] == wp[:P580] } if matches.count > 1
  next unless matches.count == 1
  wd = matches.first

  wp.keys.select { |key| key[/^P\d+/] }.each do |property|
    wp_value = wp[property]
    next if wp_value.to_s.empty?

    wd_value = wd[property] rescue binding.pry

    if wp_value.to_s == wd_value.to_s
      # warn "#{wd} matches on #{property}"
      next
    end

    if (!wd_value.to_s.empty? && (wp_value != wd_value))
      warn "*** MISMATCH for #{wp[:id]} #{property} ***: WP = #{wp_value} / WD = #{wd_value}"
      next
    end

    puts [wd[:statement], property.to_s, wp_value].join " "
  end
end

warn "## No suitable P39s for:\n\t#{no_P39s.join ' '}" if no_P39s.any?

