require 'rails_helper'

RSpec.describe "Barcodes", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/barcode/show"
      expect(response).to have_http_status(:success)
      puts "huzzah!"
    end
  end
end
