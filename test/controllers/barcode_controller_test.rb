require "test_helper"

class BarcodeControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get barcode_show_url
    assert_response :success
  end
end
