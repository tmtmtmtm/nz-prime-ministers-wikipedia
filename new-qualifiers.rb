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
  # TODO: warn which ones we're skipping (but only once each)
  next unless (wptally[wp[:id]] == 1) && (wdtally[wp[:id]] == 1)

  wd = wikidata.find(wp[:id])

  wp.keys.select { |key| key[/^P\d+/] }.each do |property|
    wp_value = wp[property]
    next if wp_value.to_s.empty?

    wd_value = wd.first[property] rescue binding.pry

    if wp_value.to_s == wd_value.to_s
      # warn "#{wd.first} matches on #{property}"
      next
    end

    if (!wd_value.to_s.empty? && (wp_value != wd_value))
      warn "*** MISMATCH for #{wp[:id]} #{property} ***: WP = #{wp_value} / WD = #{wd_value}"
      next
    end

    puts [wd.first[:statement], property.to_s, wp_value].join " "
  end
end

warn "## No suitable P39s for:\n\t#{no_P39s.join ' '}" if no_P39s.any?

