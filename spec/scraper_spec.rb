# frozen_string_literal: true

RSpec.describe Scraper do
  let(:scraper) { described_class.new }
  let(:agent) { Mechanize.new }

  describe "#scrape_page", :vcr do
    it "scrapes one page of projects with the expected fields" do
      records = []
      Timecop.freeze(Date.new(2026, 8, 29)) do
        scraper.scrape_page(agent, 0) { |record| records << record }
      end

      expect(records.count).to be_positive

      records.each do |record|
        expect(record["council_reference"]).to match(/\A\S+\z/)
        expect(record["address"]).to match(/NSW|New South Wales/i)
        expect(record["description"]).not_to be_empty
        expect(record["info_url"]).to start_with(
          "https://www.planningportal.nsw.gov.au/major-projects/projects/"
        )
        expect(record["date_scraped"]).to eq("2026-08-29")
        expect(record["on_notice_from"]).to match(/\A\d{4}-\d{2}-\d{2}\z/).or be_nil
        expect(record["on_notice_to"]).to match(/\A\d{4}-\d{2}-\d{2}\z/).or be_nil
      end
    end

    it "returns the number of projects found" do
      count = 0
      Timecop.freeze(Date.new(2026, 8, 29)) do
        count = scraper.scrape_page(agent, 0) { |_record| nil }
      end

      expect(count).to be_positive
    end
  end

  describe "#convert_date" do
    it "converts an Australian-style date to ISO 8601" do
      expect(scraper.convert_date("25/12/2025")).to eq("2025-12-25")
    end

    it "returns nil for an unparseable date" do
      expect(scraper.convert_date("not a date")).to be_nil
    end

    it "returns nil for nil" do
      expect(scraper.convert_date(nil)).to be_nil
    end
  end

  describe "#squish" do
    it "collapses all whitespace like ActiveSupport's squish" do
      expect(scraper.squish(" foo\u00A0 bar\n\tbaz ")).to eq("foo bar baz")
    end
  end
end
