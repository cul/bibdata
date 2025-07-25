require 'rails_helper'

RSpec.describe Bibdata::Scsb do
  describe '.merged_marc_record_for_barcode' do
    let(:fixture_base_dir) { Rails.root.join("spec/fixtures/sample-records/#{barcode}") }
    let(:item_record) { JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-item-record.json"))) }
    let(:location_record) { JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-location-record.json"))) }
    let(:holdings_record) { JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-holdings-record.json"))) }
    let(:source_record) { JSON.parse(File.read(File.join(fixture_base_dir, "#{barcode}-source-record.json"))) }

    let(:expected_xml) do
      marc_xml_string = File.read(File.join(fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
      Nokogiri::XML(marc_xml_string, &:noblanks).to_xml(indent: 2)
    end

    [ 'CU23392169', 'CU29937574', 'AR03426424' ].each do |sample_record_barcode|
      context "sample record #{sample_record_barcode}" do
        let(:barcode) { sample_record_barcode }
        before do
          allow(Bibdata::FolioApiClient.instance).to receive(:find_item_record).and_return(item_record)
          allow(Bibdata::FolioApiClient.instance).to receive(:find_location_record).and_return(location_record)
          allow(Bibdata::FolioApiClient.instance).to receive(:find_holdings_record).and_return(holdings_record)
          allow(Bibdata::FolioApiClient.instance).to receive(:find_source_record).and_return(source_record)
        end
        it "generates the expected xml" do
          marc_record = described_class.merged_marc_record_for_barcode(barcode)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end
      end
    end


    context "when location cannot be resolved" do
      let(:barcode) { 'CU23392169' }
      let(:location_record) { nil }
      let(:expected_xml) do
        marc_xml_string = File.read(File.join(fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
        xml_doc = Nokogiri::XML(marc_xml_string, &:noblanks)
        # Remove the 852 $b field because we are not expecting location data to be present
        xml_doc.xpath(
          '/marc:record/marc:datafield[@ind1="0" and @ind2="0" and @tag="852"]/marc:subfield[@code="b"]',
          'marc' => 'http://www.loc.gov/MARC21/slim'
        ).remove
        xml_doc.to_xml(indent: 2)
      end

      before do
        allow(Bibdata::FolioApiClient.instance).to receive(:find_item_record).and_return(item_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_location_record).and_return(location_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_holdings_record).and_return(holdings_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_source_record).and_return(source_record)
      end

      it "generates the expected xml, skipping location info (and not raising an exception)" do
        marc_record = nil
        expect {
          marc_record = described_class.merged_marc_record_for_barcode(barcode)
        }.not_to raise_error
        generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
        expect(generated_xml).to eq(expected_xml)
      end
    end
  end
end
