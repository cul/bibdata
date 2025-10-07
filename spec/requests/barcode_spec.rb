require 'rails_helper'

RSpec.describe "Barcodes", type: :request do
  let(:valid_barcode) { "CU12345678" }
  let(:invalid_barcode) { "not-valid" }
  let(:marc_record) { double(MARC::Record) }
  let(:xml_response) do
    %{
      <?xml version='1.0'?>
      <collection xmlns='http://www.loc.gov/MARC21/slim'
            xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
            xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
      <record>
        This is a fake MARC record XML response and the content inside this record element doesn't matter for these tests.
      </record>
      </collection>
    }
  end

  before do
    # merged_marc_record_for_barcode will return nil by default
    allow(Bibdata::Scsb).to receive(:merged_marc_record_for_barcode).and_return(nil)
    # merged_marc_record_for_barcode will return a marc record for a valid barcode
    allow(Bibdata::Scsb).to receive(:merged_marc_record_for_barcode).with(valid_barcode, flip_location: flip_location).and_return(marc_record)

    allow(Bibdata::MarcHelpers).to receive(:render_marc_records_as_marc_collection_xml).with(
      [marc_record]
    ).and_return(xml_response)
  end

  describe "GET /barcode/:barcode/query" do
    let(:flip_location) { false }

    it "returns a 200 OK response for a valid barcode" do
      puts "REQUEST: #{"/barcode/#{valid_barcode}/query"}"
      get "/barcode/#{valid_barcode}/query"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/xml; charset=utf-8")
      expect(response.body).to eq(xml_response)
    end

    it "returns a 404 Not Found response for an invalid barcode" do
      get "/barcode/#{invalid_barcode}/query"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /barcode/:barcode/update" do
    let(:flip_location) { true }

    let(:headers_with_invalid_authorization_token) do
      { 'Authorization' => "Bearer THIS_IS_AN_INVALID_TOKEN" }
    end

    context "when the user does not supply an auth token" do
      it "returns a 401 unauthorized response when a token is not provided" do
        post "/barcode/#{valid_barcode}/update"
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a 401 unauthorized response when an invalid token is provided" do
        post "/barcode/#{valid_barcode}/update", params: {}, headers: headers_with_invalid_authorization_token
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not result in any attempts at FOLIO record retrieval" do
        expect(Bibdata::Scsb).not_to receive(:merged_marc_record_for_barcode)
        post "/barcode/#{valid_barcode}/update"
      end
    end

    context "with a valid auth token" do
      let(:headers_with_valid_authorization_token) do
        { 'Authorization' => "Bearer #{Rails.application.config.bibdata['barcode_update_api_token']}" }
      end

      it "returns a 200 OK response for a valid barcode" do
        post "/barcode/#{valid_barcode}/update", params: {}, headers: headers_with_valid_authorization_token
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/xml; charset=utf-8")
        expect(response.body).to eq(xml_response)
      end

      it "returns a 404 Not Found response for an invalid barcode" do
        post "/barcode/#{invalid_barcode}/update", params: {}, headers: headers_with_valid_authorization_token
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
