# frozen_string_literal: true

namespace :bibdata do
  namespace :fixtures do
    task generate_test_fixtures_for_barcode: :environment do
      barcode = ENV['barcode']

      item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: barcode)

      Bibdata::Scsb.fetch_folio_records_associated_with_item(item_record) => {
        holdings_record:, holdings_permanent_location_record:, source_record:, material_type_record:
      }
      current_holdings_permanent_location_code = holdings_permanent_location_record&.fetch('code')

      marc_record = MARC::Record.new_from_hash(source_record['parsedRecord']['content'])
      Bibdata::Scsb.enhance_base_marc_record!(
        marc_record, item_record, holdings_record, current_holdings_permanent_location_code
      )

      Bibdata::FixtureHelper.write_records_to_fixture_dir(
        barcode, item_record, holdings_record, holdings_permanent_location_record,
        material_type_record, source_record, marc_record.to_xml.to_s
      )
    end
  end
end
