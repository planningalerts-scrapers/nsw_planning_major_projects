#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require "date"
require "mechanize"
require "scraperwiki"

# Scrapes major projects currently on exhibition from the NSW Planning
# Portal's major projects register and yields one record per project.
class Scraper
  PAGE_URL = "https://www.planningportal.nsw.gov.au/major-projects/projects" \
             "?status=Exhibition&lga=All&development_type=All&industry_type=All&case_type=All&page=%d"

  def self.run(&)
    new.run(&)
  end

  def run(&block)
    agent = Mechanize.new
    page_number = 0
    loop do
      puts "Getting page #{page_number}..."
      count = scrape_page(agent, page_number, &block)
      page_number += 1
      break unless count.positive?
    end
  end

  # Scrapes one page of projects on exhibition (page 0 is the first page)
  # and returns the number of project cards found.
  def scrape_page(agent, page_number)
    page = agent.get(format(PAGE_URL, page_number))
    cards = page.search(".card").select { |card| card.at(".field-field-case-id") }
    cards.each do |card|
      record = scrape_card(agent, page, card)
      if record["council_reference"].empty? || record["address"].empty?
        puts "Skipping project with missing reference or address at #{record['info_url']}"
      else
        yield record
      end
    end
    cards.count
  end

  # The listing card carries the reference, title and address; the detail
  # page carries the description and exhibition dates.
  def scrape_card(agent, page, card)
    url = (page.uri + card.at(".field-node-link a")["href"]).to_s
    detail = agent.get(url)

    {
      "council_reference" => squish(card.at(".field-field-case-id").text),
      "address" => address(card),
      "description" => description(detail, card),
      "info_url" => url,
      "date_scraped" => Date.today.to_s
    }.merge(exhibition_dates(detail))
  end

  # The project address sits beside a pin icon on the listing card
  def address(card)
    pin = card.at(".icon--pin")
    return "" if pin.nil?

    text = squish(pin.parent.text)
    return text if text.empty? || text.match?(/\bNSW\b|\bNew South Wales\b/i)

    "#{text}, NSW"
  end

  # The project description from the detail page, falling back to the
  # listing card's title
  def description(detail, card)
    node = detail.at(".field-field-project-description")
    text = node && squish(node.text)
    text.to_s.empty? ? squish(card.at(".card__title").text) : text
  end

  # The "Exhibition Start-End Date" row holds two <time> elements with
  # Australian-style display dates
  def exhibition_dates(detail)
    row = detail.search(".row").find { |r| r.text.match?(/Exhibition Start-End Date/i) }
    dates = row ? row.search("time").map { |time| convert_date(time.text) } : []
    { "on_notice_from" => dates[0], "on_notice_to" => dates[1] }.compact
  end

  def convert_date(value)
    Date.strptime(squish(value.to_s), "%d/%m/%Y").to_s
  rescue ArgumentError, TypeError
    nil
  end

  # Equivalent of ActiveSupport's String#squish
  def squish(text)
    text.gsub(/[[:space:]]+/, " ").strip
  end
end

if __FILE__ == $PROGRAM_NAME
  count = 0
  Scraper.run do |record|
    puts "Saving #{record['council_reference']}..."
    ScraperWiki.save_sqlite(["council_reference"], record)
    count += 1
  end
  puts "Finished - added #{count} records."
end
