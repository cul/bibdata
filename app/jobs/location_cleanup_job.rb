# frozen_string_literal: true

# This job is generally queued by a POST request to the /barcodes/#{barcode}/update endpoint, which is made by the
# ReCAP SCSB system during an item accession.  During that request, we synchronously flip the parent holdings location,
# and then we queue this job to asynchronously perform post-accession actions (like clearing the holdings temporary
# location, item permanent location, and item temporary location).
class LocationCleanupJob < ApplicationJob
  queue_as :location_cleanup

  def perform(barcode) # rubocop:disable Metrics/MethodLength
    # Clear item record permanent location
    Bibdata::FolioApiClient.instance.update_item_record_location(
      item_barcode: barcode,
      location_type: :permanent,
      new_location_code: nil
    )

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
end
