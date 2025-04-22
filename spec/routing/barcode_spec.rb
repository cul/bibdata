require 'rails_helper'

RSpec.describe "Barcodes", type: :routing do
  describe "GET /show" do
    it "returns http success" do
      expect(get: "/barcode/test").to route_to(
        controller: "barcode",
        action: "show",
        barcode: "test"
      )
    end
  end
end
