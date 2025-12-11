# frozen_string_literal: true

class BarcodeController < ApplicationController
  before_action :authenticate, only: [:update]
  skip_before_action :verify_authenticity_token, only: [:update] # No need for CSRF token for API token auth endpoint

  rescue_from Faraday::Error, with: :handle_faraday_error
  rescue_from Bibdata::Exceptions::UnresolvableHoldingsPermanentLocationError,
              with: :unresolvable_holdings_location_error

  def query
    barcode = params[:barcode] # Example: 'CU23392169'
    marc_record = nil
    duration = Benchmark.measure do
      marc_record = Bibdata::Scsb.merged_marc_record_for_barcode(barcode, flip_location: false)
    end

    Rails.logger.info('Performance measurement: '\
                      "Request for /barcode/#{barcode}/query completed in #{duration.real} seconds.")

    return render_not_found barcode if marc_record.nil?

    render xml: Bibdata::MarcHelpers.render_marc_records_as_marc_collection_xml([marc_record])
  end

  def update
    barcode = params[:barcode] # Example: 'CU23392169'
    marc_record = nil
    duration = Benchmark.measure do
      marc_record = Bibdata::Scsb.merged_marc_record_for_barcode(barcode, flip_location: true)
    end

    Rails.logger.info('Performance measurement: '\
                      "Request for /barcode/#{barcode}/update completed in #{duration.real} seconds.")

    return render_not_found barcode if marc_record.nil?

    render xml: Bibdata::MarcHelpers.render_marc_records_as_marc_collection_xml([marc_record])
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Rails.application.config.bibdata['barcode_update_api_token'])
    end
  end

  def render_not_found(barcode)
    render plain: "Barcode #{barcode} was not found.", status: :not_found
  end

  def handle_faraday_error(exception)
    Rails.logger.error(
      "Returning 500 status because an unexpected #{exception.class.name} occurred: "\
      "#{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
    )
    render plain: 'An error occurred while connecting to the backing ILS.', status: :internal_server_error
  end

  def unresolvable_holdings_location_error(exception)
    Rails.logger.error(
      "Returning 500 status because an unexpected #{exception.class.name} occurred: "\
      "#{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
    )
    render plain: 'Unable to resolve the holdings permanent location for this record.', status: :internal_server_error
  end
end
