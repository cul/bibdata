require 'rails_helper'

RSpec.describe Bibdata::Scsb do
  describe '.merged_marc_record_for_barcode' do
    [ 'CU23392169', 'CU29937574' ].each do |barcode|
      context "sample record #{barcode}" do
        let(:fixture_base_dir) { Rails.root.join("spec/fixtures/sample-records/#{barcode}") }
        let(:expected_xml) do
          marc_xml_string = File.read(File.join(fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
          Nokogiri::XML(marc_xml_string, &:noblanks).to_xml(indent: 2)
        end

        before do
          allow(Bibdata::FolioApiClient.instance).to receive(:find_item_record).and_return(
            JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-item-record.json")))
          )
          allow(Bibdata::FolioApiClient.instance).to receive(:find_location_record).and_return(
            JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-location-record.json")))
          )
          allow(Bibdata::FolioApiClient.instance).to receive(:find_holdings_record).and_return(
            JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-holdings-record.json")))
          )
          allow(Bibdata::FolioApiClient.instance).to receive(:find_source_record).and_return(
            JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-source-record.json")))
          )
        end
        it "generates the expected xml " do
          marc_record = described_class.merged_marc_record_for_barcode(barcode)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end
      end
    end
  end
end
