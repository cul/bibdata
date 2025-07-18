module Bibdata::FixtureHelper
  def self.write_records_to_fixture_dir(barcode, item_record, location_record, holdings_record, source_record, generated_scsb_marc_xml_string)
    base_dir = Rails.root.join("spec/fixtures/sample-records/#{barcode}")
    FileUtils.mkdir_p(base_dir)
    File.binwrite(File.join(base_dir, "#{barcode}-item-record.json"), JSON.generate(item_record))
    File.binwrite(File.join(base_dir, "#{barcode}-location-record.json"), JSON.generate(location_record))
    File.binwrite(File.join(base_dir, "#{barcode}-holdings-record.json"), JSON.generate(holdings_record))
    File.binwrite(File.join(base_dir, "#{barcode}-source-record.json"), JSON.generate(source_record))
    File.binwrite(File.join(base_dir, "#{barcode}-generated-scsb-marc-xml.xml"), Nokogiri::XML(generated_scsb_marc_xml_string, &:noblanks).to_xml(indent: 2))
  end
end
