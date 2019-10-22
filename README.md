## To run

Install Ruby 2.5 or newer. (I recommend [rvm](https://rvm.io) for a quick & easy install.)

If your version is newer than 2.5, edit the expected version number in `bin/Gemfile`.

Then:

    cd bin
    bundle  # install dependencies

    bundle exec ruby midterm_ratings.rb path_to_spreadsheet_export.csv

    bundle exec ruby final_ratings.rb path_to_spreadsheet_export.csv
