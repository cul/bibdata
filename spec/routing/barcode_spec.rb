require 'rails_helper'

RSpec.describe "/barcode routes", type: :routing do
  describe "/barcode/:barcode/query" do
    it "routes as expected for an alphanumeric barcode" do
      expect(:get => "/barcode/AR03426424/query").to route_to(
        controller: "barcode",
        action: "query",
        barcode: "AR03426424"
      )
    end

    it "routes as expected for a Code 39 barcode that ends with a non-alphanumeric character" do
      expect(:get => "/barcode/3500500741637+/query").to route_to(
        controller: "barcode",
        action: "query",
        barcode: "3500500741637+"
      )
    end

    it "routes as expected for a Code 39 barcode that ends with a url-encoded non-alphanumeric character" do
      expect(:get => "/barcode/3500500741637%20/query").to route_to(
        controller: "barcode",
        action: "query",
        barcode: "3500500741637 "
      )
    end
  end
end
