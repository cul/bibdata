# frozen_string_literal: true

namespace :bibdata do
  namespace :clear do
    task temp_locations: :environment do
      barcodes = ENV['barcodes'].split(',')

      num_barcodes_to_clear = barcodes.length
      barcodes.each_with_index do |barcode, i|
        puts "(#{i + 1} of #{num_barcodes_to_clear}) Clearing item and parent temporary locations for: #{barcode}"
        # Clear item record temporary location
        Bibdata::FolioApiClient.instance.update_item_record_location(
          item_barcode: barcode,
          location_type: :temporary,
          new_location_code: nil
        )

        # Clear parent holdings record temporary location
        Bibdata::FolioApiClient.instance.update_item_parent_holdings_record_location(
          item_barcode: barcode,
          location_type: :temporary,
          new_location_code: nil
        )
      end

      puts 'Done'
    end
  end
end
