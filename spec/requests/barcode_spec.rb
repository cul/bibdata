require 'rails_helper'

RSpec.describe "Barcodes", type: :request do
  describe "GET /show" do
    let(:test_barcode) { "test" }
    let(:test_xml) { "<record><title>Test Title</title></record>" }

    it "returns XML and OK response" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(test_xml)

      get "/barcode/#{test_barcode}"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/xml; charset=utf-8")
      expect(response.body).to eq(test_xml)
    end

    it "returns Not Found code with bad request" do
      expect(Bibdata::Scsb).to receive(:merged_marc_collection_xml_for_barcode).and_return(nil)

      get "/barcode/#{test_barcode}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
