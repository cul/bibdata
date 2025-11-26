require 'rails_helper'

RSpec.describe Bibdata::Scsb do
  let(:fixtures_base_dir) { Rails.root.join("spec/fixtures") }
  let(:barcode_fixture_base_dir) { Rails.root.join(fixtures_base_dir, "sample-records/#{barcode}") }

  describe '.merged_marc_record_for_barcode' do
    let(:item_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-item-record.json"))) }
    let(:location_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-holdings-permanent-location-record.json"))) }
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
          marc_record = described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end

        it "calls the perform_location_flip! method when perform_location_flip is true" do
          expect(Bibdata::Scsb).to receive(:perform_location_flip!)
          described_class.merged_marc_record_for_barcode(barcode, flip_location: true)
        end

        it "does not call the perform_location_flip! method when perform_location_flip is false" do
          expect(Bibdata::Scsb).not_to receive(:perform_location_flip!)
          described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
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
        marc_record = described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
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

      it "raises an exception" do
        expect {
          described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
        }.to raise_error(Bibdata::Exceptions::UnresolvableHoldingsPermanentLocationError)
      end
    end
  end

  describe 'location flipping logic' do
    let(:barcode) { 'CU23392169' }
    let(:item_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-item-record.json"))) }
    let(:holdings_record) { JSON.parse(File.read(File.join(barcode_fixture_base_dir, "#{barcode}-holdings-record.json"))) }

    let(:current_holdings_permanent_location_record) {
      JSON.parse(File.read(File.join(fixtures_base_dir, "ave4off-location-record.json")))
    }
    let(:current_holdings_permanent_location_code) {
      current_holdings_permanent_location_record['code']
    }
    let(:material_type_name) { 'Book' }

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
      allow(BarcodeUpdateErrorMailer).to receive(:with).with(
        barcode: barcode, errors: an_instance_of(Array)
      ).and_return(barcode_update_error_mailer)
    end

    describe '.perform_location_flip!' do
      it 'calls the expected methods with the expected parameters' do
        expect(Bibdata::Scsb).to receive(:update_holdings_permanent_location_if_required!).with(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
        expect(Bibdata::Scsb).to receive(:clear_item_permanent_location_if_present!).with(
          barcode, item_record
        )
        expect(Bibdata::Scsb).to receive(:send_notification_email_if_temporary_locations_found).with(
          barcode, item_record, holdings_record
        )

        Bibdata::Scsb.perform_location_flip!(
          barcode, item_record, holdings_record, current_holdings_permanent_location_code, material_type_name
        )
      end
    end

    describe '.update_holdings_permanent_location_if_required!' do
      let(:flipped_location_code) { 'off,ave' }
      it  'performs a holdings permanent location update if the current holdings permanent location '\
          'is different from the flipped code' do
        allow(Bibdata::OffsiteLocationFlipper).to receive(
          :location_code_to_recap_flipped_location_code
        ).and_return(flipped_location_code)

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Trying to change parent holdings permanent location/)
        expect(Bibdata::FolioApiClient.instance).to receive(
          :update_item_parent_holdings_record_location
        ).with(
          item_barcode: barcode, location_type: :permanent, new_location_code: flipped_location_code
        )
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Changed parent holdings permanent location/)

        Bibdata::Scsb.update_holdings_permanent_location_if_required!(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
      end

      it 'does not perform an update if current holdings permanent location code equals the flipped code' do
        allow(Bibdata::OffsiteLocationFlipper).to receive(
          :location_code_to_recap_flipped_location_code
        ).and_return(current_holdings_permanent_location_code)

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/No holdings permanent location flip needed/)
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_parent_holdings_record_location)

        Bibdata::Scsb.update_holdings_permanent_location_if_required!(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
      end

      it  'does not perform an update if the current location cannot be mapped to a flipped location, '\
          'and it sends an email notification' do
        allow(Bibdata::OffsiteLocationFlipper).to receive(
          :location_code_to_recap_flipped_location_code
        ).and_return(nil)

        expect(Bibdata::FolioApiClient.instance).not_to receive(
          :update_item_parent_holdings_record_location
        )

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Unable to map current location to flipped location/)
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])

        Bibdata::Scsb.update_holdings_permanent_location_if_required!(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
      end

      it  'properly handles the case when update_item_parent_holdings_record_location '\
          'raises a Bibdata::Exceptions::LocationNotFoundError' do
        allow(Bibdata::OffsiteLocationFlipper).to receive(
          :location_code_to_recap_flipped_location_code
        ).and_return(flipped_location_code)
        error_message = 'But something went wrong!'
        allow(Bibdata::FolioApiClient.instance).to receive(
          :update_item_parent_holdings_record_location
        ).and_raise(Bibdata::Exceptions::LocationNotFoundError, error_message)

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Trying to change parent holdings permanent location/)
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/#{Regexp.escape(error_message)}/)
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])

        Bibdata::Scsb.update_holdings_permanent_location_if_required!(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
      end
    end

    describe '.clear_item_permanent_location_if_present!' do
      it 'clears the item permanent location if the item currently has a permanent location' do

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Trying to clear item permanent location/)
        expect(Bibdata::FolioApiClient.instance).to receive(
          :update_item_record_location
        ).with(
          item_barcode: barcode, location_type: :permanent, new_location_code: nil
        )
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Cleared item permanent location/)

        Bibdata::Scsb.clear_item_permanent_location_if_present!(
          barcode, item_record
        )
      end

      it 'does not try to clear the item permanent location if the item does not currently have a permanent location' do
        item_record['permanentLocationId'] = nil
        expect(Bibdata::FolioApiClient.instance).not_to receive(:update_item_record_location)
        Bibdata::Scsb.clear_item_permanent_location_if_present!(
          barcode, item_record
        )
      end
    end

    describe '.send_notification_email_if_temporary_locations_found' do
      it 'sends an email with one error if the item has a temporary location set' do
        item_record['temporaryLocationId'] = 'some-location-id'
        holdings_record.delete('temporaryLocationId')
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Found unwanted item temporary location/)
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])
        Bibdata::Scsb.send_notification_email_if_temporary_locations_found(
          barcode, item_record, holdings_record
        )
      end

      it "sends an email with one error if the item's parent holdings record has a temporary location set" do
        item_record.delete('temporaryLocationId')
        holdings_record['temporaryLocationId'] = 'some-location-id'
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Found unwanted parent holdings temporary location/)
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(barcode: barcode, errors: [an_instance_of(String)])
        Bibdata::Scsb.send_notification_email_if_temporary_locations_found(
          barcode, item_record, holdings_record
        )
      end

      it "sends an email with two errors if the item and its parent holdings record both have temporary locations set" do
        item_record['temporaryLocationId'] = 'some-location-id'
        holdings_record['temporaryLocationId'] = 'some-location-id'

        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Found unwanted item temporary location/)
        expect(Bibdata::Scsb.location_change_logger).to receive(:unknown).with(/Found unwanted parent holdings temporary location/)
        expect(BarcodeUpdateErrorMailer).to receive(:with).with(
          barcode: barcode, errors: [an_instance_of(String), an_instance_of(String)]
        )
        Bibdata::Scsb.send_notification_email_if_temporary_locations_found(
          barcode, item_record, holdings_record
        )
      end

      it 'does not try to send an email if the item and its parent holdings record do not have temporary locations set' do
        expect(BarcodeUpdateErrorMailer).not_to receive(:with)
        Bibdata::Scsb.send_notification_email_if_temporary_locations_found(
          barcode, item_record, holdings_record
        )
      end
    end
  end

  describe '.location_change_logger' do
    it 'returns a logger' do
      expect(Bibdata::Scsb.location_change_logger).to be_a(ActiveSupport::Logger)
    end

    it 'returns the same logger instance every time' do
      logger = Bibdata::Scsb.location_change_logger
      expect(Bibdata::Scsb.location_change_logger).to equal(logger)
    end
  end
end
