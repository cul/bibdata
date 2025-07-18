# frozen_string_literal: true

class BarcodeController < ApplicationController
  # Client: This endpoint is used by the ReCAP inventory management system, LAS,
  #   to pull data from our ILS when items are accessioned -- see PU bibdata app (https://github.com/pulibrary/bibdata/blob/3e8888ce06944bb0fd0e3da7c13f603edf3d45a5/app/controllers/barcode_controller.rb#L6)
  #   # TODO : DOCUMENT + flesh out implementation
  def show
    barcode = params[:barcode] # Example: 'CU23392169'
    return render_not_found barcode unless valid_barcode(barcode)

    xml = Bibdata::Scsb.merged_marc_collection_xml_for_barcode(barcode)
    return render_not_found barcode if xml.nil?

    render xml: xml
  end

  private

  def render_not_found(barcode)
    render plain: "Barcode #{barcode} was not found.", status: :not_found
  end

  # TODO: implement
  def valid_barcode(_barcode)
    true
  end
end
