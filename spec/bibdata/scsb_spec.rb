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

    context "CGD logic based on the item record's bibliographic record MARC data" do
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
                { 'x' => value_876x }
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
        ).first.content = expected_xml_876_x_value
        xml_doc.xpath(
          '/marc:record/marc:datafield[@tag="876"]/marc:subfield[@code="h"]',
          'marc' => 'http://www.loc.gov/MARC21/slim'
        ).first.content = expected_xml_876_h_value
        xml_doc.to_xml(indent: 2)
      end

      before do
        allow(Bibdata::FolioApiClient.instance).to receive(:find_item_record).and_return(item_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_location_record).and_return(location_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_holdings_record).and_return(holdings_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_material_type_record).and_return(material_type_record)
        allow(Bibdata::FolioApiClient.instance).to receive(:find_source_record).and_return(source_record)
      end

      context "when the instance record MARC data has an 876 $x value of 'Committed'" do
        let(:value_876x) { Bibdata::Scsb::Constants::CGD_COMMITTED }
        let(:expected_xml_876_x_value) { Bibdata::Scsb::Constants::CGD_COMMITTED }
        let(:expected_xml_876_h_value) { Bibdata::Scsb::Constants::USE_RESTRICTION_BLANK }
        it "generates the expected xml, which has an 876 $x value of 'Committed'" do
          marc_record = described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end
      end

      context "when the instance record MARC data has an 876 $x value of 'Private'" do
        let(:value_876x) { Bibdata::Scsb::Constants::CGD_PRIVATE }
        let(:expected_xml_876_x_value) { Bibdata::Scsb::Constants::CGD_PRIVATE }
        let(:expected_xml_876_h_value) { Bibdata::Scsb::Constants::USE_RESTRICTION_SUPERVISED_USE }
        it "generates the expected xml, which has an 876 $x value of 'Private'" do
          marc_record = described_class.merged_marc_record_for_barcode(barcode, flip_location: false)
          generated_xml = Nokogiri::XML(marc_record.to_xml.to_s, &:noblanks).to_xml(indent: 2)
          expect(generated_xml).to eq(expected_xml)
        end
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
      allow(DailyErrorMailer).to receive(:with).with(
        errors: an_instance_of(Array)
      ).and_return(barcode_update_error_mailer)
    end

    describe '.perform_location_flip!' do
      it 'calls the expected methods with the expected parameters' do
        expect(Bibdata::Scsb).to receive(:update_holdings_permanent_location_if_required!).with(
          barcode, current_holdings_permanent_location_code, material_type_name
        )
        expect(LocationCleanupJob).to receive(:perform_later).with(barcode)

        Bibdata::Scsb.perform_location_flip!(
          barcode, current_holdings_permanent_location_code, material_type_name
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
        expect(BarcodeUpdateError).to receive(:create).with(barcode: barcode, error_message: an_instance_of(String))

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
        expect(BarcodeUpdateError).to receive(:create).with(barcode: barcode, error_message: an_instance_of(String))

        Bibdata::Scsb.update_holdings_permanent_location_if_required!(
          barcode, current_holdings_permanent_location_code, material_type_name
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

  describe '.collection_group_designation_for_item' do
    it "falls back to CGD shared when no other rules match" do
      folio_item_record = instance_double('Item Record')
      allow(folio_item_record).to receive(:[]).with('barcode').and_return("ZZ1234567")
      expect(
        described_class.collection_group_designation_for_item(folio_item_record, 'example-location', '')
      ).to eq(Bibdata::Scsb::Constants::CGD_SHARED)
    end

    context "CGD for a barcode on our private barcode prefix list" do
      Bibdata::Scsb::Constants::CGD_PRIVATE_BARCODE_PREFIXES.each do |private_barcode_prefix|
        it "returns 'Private' for private barcode prefix #{private_barcode_prefix}" do
          folio_item_record = instance_double('Item Record')
          allow(folio_item_record).to receive(:[]).with('barcode').and_return("#{private_barcode_prefix}1234567")
          expect(
            described_class.collection_group_designation_for_item(folio_item_record, 'example-location', 'any 876 $x value')
          ).to eq(Bibdata::Scsb::Constants::CGD_PRIVATE)
        end
      end
    end

    context "CGD for a location code on our private location code list" do
      let(:folio_item_record) {
        item_rec = instance_double('Item Record')
        allow(item_rec).to receive(:[]).with('barcode').and_return('non-private-barcode')
        item_rec
      }

      Bibdata::Scsb::Constants::CGD_PRIVATE_LOCATION_CODES.each do |private_location_code|
        it "returns 'Private' for private location code #{private_location_code}" do
          expect(
            described_class.collection_group_designation_for_item(folio_item_record, private_location_code, 'any 876 $x value')
          ).to eq(Bibdata::Scsb::Constants::CGD_PRIVATE)
        end
      end
    end

    context "when the instance record MARC data has an 876 $x value of 'Private'" do
      let(:folio_item_record) {
        item_rec = instance_double('Item Record')
        allow(item_rec).to receive(:[]).with('barcode').and_return('non-private-barcode')
        item_rec
      }
      it "returns 'Private'" do
        expect(
          described_class.collection_group_designation_for_item(folio_item_record, 'example-location', Bibdata::Scsb::Constants::CGD_PRIVATE)
        ).to eq(Bibdata::Scsb::Constants::CGD_PRIVATE)
      end
    end

    context "when the instance record MARC data has an 876 $x value of 'Committed'" do
      let(:folio_item_record) {
        item_rec = instance_double('Item Record')
        allow(item_rec).to receive(:[]).with('barcode').and_return('non-private-barcode')
        item_rec
      }
      it "returns 'Private'" do
        expect(
          described_class.collection_group_designation_for_item(folio_item_record, 'example-location', Bibdata::Scsb::Constants::CGD_COMMITTED)
        ).to eq(Bibdata::Scsb::Constants::CGD_COMMITTED)
      end
    end
  end
end
