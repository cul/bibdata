require 'rails_helper'

RSpec.describe "Barcodes", type: :request do

  # TODO: Delete the describe block below once we stop supporting this endpoint (in the near future)
  describe "GET /barcode/:barcode" do
    let(:test_barcode) { "test" }
    let(:xml_response) { "<record><title>Test Title</title></record>" }

    it "returns a 200 OK response for a valid barcode" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(xml_response)

      get "/barcode/#{test_barcode}"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/xml; charset=utf-8")
      expect(response.body).to eq(xml_response)
    end

    it "returns a 404 Not Found response for an invalid barcode" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(nil)

      get "/barcode/#{test_barcode}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /barcode/:barcode/query" do
    let(:test_barcode) { "test" }
    let(:xml_response) { "<record><title>Test Title</title></record>" }

    it "returns a 200 OK response for a valid barcode" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(xml_response)

      get "/barcode/#{test_barcode}/query"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/xml; charset=utf-8")
      expect(response.body).to eq(xml_response)
    end

    it "returns a 404 Not Found response for an invalid barcode" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(nil)

      get "/barcode/#{test_barcode}/query"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /barcode/:barcode/update" do
    let(:test_barcode) { "test" }
    let(:xml_response) { "<record><title>Test Title</title></record>" }

    let(:headers_with_invalid_authorization_token) do
      { 'Authorization' => "Bearer THIS_IS_AN_INVALID_TOKEN" }
    end

    context "when the user does not supply an auth token" do
      it "returns a 401 unauthorized response when a token is not provided" do
        post "/barcode/#{test_barcode}/update"
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a 401 unauthorized response when an invalid token is provided" do
        post "/barcode/#{test_barcode}/update", params: {}, headers: headers_with_invalid_authorization_token
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not result in any attempts at FOLIO record retrieval" do
        expect(Bibdata::Scsb).not_to receive(:merged_marc_collection_xml_for_barcode)
        post "/barcode/#{test_barcode}/update"
      end
    end

    context "with a valid auth token" do
      let(:headers_with_valid_authorization_token) do
        { 'Authorization' => "Bearer #{BIBDATA[:barcode_update_api_token]}" }
      end

      it "returns a 200 OK response for a valid barcode" do
        expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(xml_response)

        post "/barcode/#{test_barcode}/update", params: {}, headers: headers_with_valid_authorization_token
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/xml; charset=utf-8")
        expect(response.body).to eq(xml_response)
      end

      it "returns a 404 Not Found response for an invalid barcode" do
        expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(nil)

        post "/barcode/#{test_barcode}/update", params: {}, headers: headers_with_valid_authorization_token
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
