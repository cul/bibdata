# frozen_string_literal: true

class BarcodeController < ApplicationController
  before_action :authenticate, only: [:update]

  def query
    barcode = params[:barcode] # Example: 'CU23392169'

    marc_record = Bibdata::Scsb.merged_marc_record_for_barcode(barcode, flip_location: false)
    return render_not_found barcode if marc_record.nil?

    render xml: Bibdata::MarcHelpers.render_marc_records_as_marc_collection_xml([marc_record])
  end

  def update
    barcode = params[:barcode] # Example: 'CU23392169'

    marc_record = Bibdata::Scsb.merged_marc_record_for_barcode(barcode, flip_location: true)
    return render_not_found barcode if marc_record.nil?

    render xml: Bibdata::MarcHelpers.render_marc_records_as_marc_collection_xml([marc_record])
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, BIBDATA[:barcode_update_api_token])
    end
  end

  def render_not_found(barcode)
    render plain: "Barcode #{barcode} was not found.", status: :not_found
  end
end
