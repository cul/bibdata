class BarcodeController < ApplicationController
  # Client: This endpoint is used by the ReCAP inventory management system, LAS,
  #   to pull data from our ILS when items are accessioned -- see PU bibdata app (https://github.com/pulibrary/bibdata/blob/3e8888ce06944bb0fd0e3da7c13f603edf3d45a5/app/controllers/barcode_controller.rb#L6)
  #   # TODO : DOCUMENT + flesh out implementation
  def show
    barcode = params[:barcode]
    return render_not_found barcode if !valid_barcode(barcode)
    puts "we are in the show action! got the barcode #{barcode}"
    response = erics_script(barcode)
    return render_not_found barcode if response == nil
    render xml: response
  end

  private ######################################################################

  def render_not_found(barcode)
    render plain: "Barcode #{barcode} was not found.", status: :not_found
  end

  # TODO: implement
  def valid_barcode(barcode)
    true
  end

  # TODO : Implement
  # for now, this method just simulates using eric's logic to fetch data from
  # FOLIO and create a complete MARC response for the client
  def erics_script(barcode)
    puts "erics_script():"
    puts "Getting the record with barcode #{barcode}..."
    # sleep(0.5)
    reader = MARC::XMLReader.new("example.mrc")
    response = StringIO.new
    MARC::UnsafeXMLWriter.new(response) do |writer|
      reader.each do |record|
        writer.write(record)
      end
    end
    response.string
  end
end

# TODO -- use the other example marc file (here: https://bibdata.cul.columbia.edu/barcode/CU23392169)
# --> set up our app to use a client that fetches this data..?
