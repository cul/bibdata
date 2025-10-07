require 'rails_helper'

RSpec.describe Bibdata::Scsb do
  let(:fixtures_base_dir) { Rails.root.join("spec/fixtures") }
  let(:barcode_fixture_base_dir) { Rails.root.join(fixtures_base_dir, "sample-records/#{barcode}") }

  describe '.merged_marc_record_for_barcode' do
    let(:item_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-item-record.json"))) }
    let(:location_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-location-record.json"))) }
    let(:holdings_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-holdings-record.json"))) }
    let(:material_type_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-material-type-record.json"))) }
    let(:source_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-source-record.json"))) }

    let(:expected_xml) do
      marc_xml_string = File.read(File.join(barcode_fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
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
          allow(Bibdata::FolioApiClient.instance).to receive(:find_material_type_record).and_return(material_type_record)
        end
        it "generates the expected xml" do
          marc_record = described_class.merged_marc_record_for_barcode(barcode)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end
      end
    end


    context "when the original record's bibliographic marc data has an 876 $x value of 'Committed'" do
      let(:barcode) { 'CU23392169' }
      let(:source_record) {
        record = JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-source-record.json")))
        # Remove any existing 876 fields
        record['parsedRecord']['content']['fields'].delete_if { |f| f.keys.include?('876') }
        # Add a new 876 with an $x value of 'Committed'
        record['parsedRecord']['content']['fields'].push(
          {
            '876' => {
              'ind1' => ' ',
              'ind2'=> ' ',
              'subfields'=> [
                { 'x' => 'Committed' }
              ]
            }
          }
        )

        record
      }
      let(:expected_xml) do
        marc_xml_string = File.read(File.join(barcode_fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
        xml_doc = Nokogiri::XML(marc_xml_string, &:noblanks)
        # We are expecting the output 876 to have amn 876 $x value of 'Committed'
        xml_doc.xpath(
          '/marc:record/marc:datafield[@tag="876"]/marc:subfield[@code="x"]',
          'marc' => 'http://www.loc.gov/MARC21/slim'
        ).first.content = Bibdata::Scsb::Constants::CGD_COMMITTED
        xml_doc.to_xml(indent: 2)
      end

      before do
        allow(Bibdata::FolioApiClient.instance).to receive(:find_item_record).and_return(item_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_location_record).and_return(location_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_holdings_record).and_return(holdings_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_material_type_record).and_return(material_type_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_source_record).and_return(source_record)
      end

      it "generates the expected xml, which has an 876 $x value of 'Committed'" do
        marc_record = described_class.merged_marc_record_for_barcode(barcode)
        generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
        expect(generated_xml).to eq(expected_xml)
      end
    end

    context "when location cannot be resolved" do
      let(:barcode) { 'CU23392169' }
      let(:location_record) { nil }
      let(:expected_xml) do
        marc_xml_string = File.read(File.join(barcode_fixture_base_dir, "#{barcode}-generated-scsb-marc-xml.xml"))
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
        allow(Bibdata::FolioApiClient.instance).to receive(:find_material_type_record).and_return(material_type_record)
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

  describe '.perform_location_flip!' do
    let(:current_location_record) {
      JSON.parse(File.read(File.join(fixtures_base_dir, "ave4off-location-record.json")))
    }
    let(:barcode) { 'CU23392169' }
    let(:item_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-item-record.json"))) }
    let(:holdings_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-holdings-record.json"))) }
    let(:flipped_location_code) { 'off,ave' }

    let(:mail_message_object) do
      dbl = instance_double(Mail::Message)
      allow(dbl).to receive(:deliver).and_return(dbl) # The deliver method returns the mail message object
      dbl
    end
    let(:barcode_update_error_mailer) do
      mailer = double(ActionMailer::Parameterized::Mailer)
      allow(mailer).to receive(:generate_email).and_return(mail_message_object)
      mailer
    end

    before do
      allow(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)]).and_return(barcode_update_error_mailer)
    end

    context "when flipped_location_code is nil" do
      let(:flipped_location_code) { nil }

      it "does not update the item or holdings locations, logs an error, and sends an error notification email" do
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_record_permanent_location)
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_parent_holdings_record_permanent_location)
        expect(Rails.logger).to receive(:error).with(
          /The current location \(ave4off\) could not be mapped to a flipped location code/
        )
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])
        expect(mail_message_object).to receive(:deliver)

        described_class.perform_location_flip!(current_location_record, flipped_location_code, item_record, holdings_record)
      end
    end

    context "when current location equals the item temporary location" do
      before do
        item_record['temporaryLocationId'] = current_location_record['id']
      end

      it "does not update the item or holdings locations, logs an error, and sends an error notification email" do
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_record_permanent_location)
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_parent_holdings_record_permanent_location)
        expect(Rails.logger).to receive(:error).with(
          /problem: Item effectiveLocationId matches item temporaryLocationId/
        )
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])
        expect(mail_message_object).to receive(:deliver)

        described_class.perform_location_flip!(current_location_record, flipped_location_code, item_record, holdings_record)
      end
    end

    context "when current location equals the item permanent location" do
      before do
        item_record['permanentLocationId'] = current_location_record['id']
      end

      it "updates the item permanent location and does not modify the holdings location" do
        expect(Bibdata::FolioApiClient.instance).to receive(:update_item_record_permanent_location).with(
          item_barcode: barcode,
          location_type: :permanent,
          new_location_code: flipped_location_code
        )
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_parent_holdings_record_permanent_location)

        described_class.perform_location_flip!(current_location_record, flipped_location_code, item_record, holdings_record)
      end
    end










    context "when current location equals the holdings temporary location" do
      before do
        holdings_record['temporaryLocationId'] = current_location_record['id']
      end

      it "does not update the item or holdings locations, logs an error, and sends an error notification email" do
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_record_permanent_location)
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_parent_holdings_record_permanent_location)
        expect(Rails.logger).to receive(:error).with(
          /problem: Item effectiveLocationId matches parent holdings temporaryLocationId/
        )
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])
        expect(mail_message_object).to receive(:deliver)

        described_class.perform_location_flip!(current_location_record, flipped_location_code, item_record, holdings_record)
      end
    end

    context "when current location equals the holdings permanent location" do
      before do
        holdings_record['permanentLocationId'] = current_location_record['id']
      end

      it "updates the holdings permanent location and does not modify the item location" do
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_record_permanent_location)
        expect(Bibdata::FolioApiClient.instance).to receive(:update_item_parent_holdings_record_permanent_location).with(
          item_barcode: barcode,
          location_type: :permanent,
          new_location_code: flipped_location_code
        )

        described_class.perform_location_flip!(current_location_record, flipped_location_code, item_record, holdings_record)
      end
    end
  end
end
