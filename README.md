# NSW Department of Planning Major Project Assessments

This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

It scrapes major projects currently on exhibition from the
[NSW Planning Portal's major projects register](https://www.planningportal.nsw.gov.au/major-projects/projects?status=Exhibition&lga=All&development_type=All&industry_type=All&case_type=All).

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## To run the scraper

    bundle exec ruby scraper.rb

### Expected output

    Getting page 0...
    Saving SSD-71373460-Mod-1...
    Saving MP07_0026-Mod-11...
    ...
    Getting page 2...
    Finished - added 17 records.

Execution time under a minute

## To run the tests

    bundle exec rspec

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit
