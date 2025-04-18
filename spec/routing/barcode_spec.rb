require 'rails_helper'

RSpec.describe "Barcodes", type: :routing do
  describe "GET /show" do
    it "returns http success" do
      puts "victory !!!!"
      expect(get: "/barcode/test").to route_to(
        controller: "barcode",
        action: "show",
        barcode: "test"
      )
      puts "victory!"
    end
  end
end
