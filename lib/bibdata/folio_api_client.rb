# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
class Bibdata::FolioApiClient < FolioApiClient # rubocop:disable Metrics/ClassLength
  def self.instance(reload: false)
    @instance = self.new(self.default_folio_api_client_configuration) if @instance.nil? || reload
    @instance
  end

  def self.default_folio_api_client_configuration
    FolioApiClient::Configuration.new(
      url: Rails.application.config.folio[:url],
      username: Rails.application.config.folio[:username],
      password: Rails.application.config.folio[:password],
      tenant: Rails.application.config.folio[:tenant],
      timeout: Rails.application.config.folio[:timeout]
    )
  end

  def location_field_name_for_type(location_type)
    case location_type
    when :permanent
      'permanentLocationId'
    when :temporary
      'temporaryLocationId'
    else
      raise ArgumentError, "Unknown location type: #{location_type}"
    end
  end

  def update_item_record_location(item_barcode:, location_type:, new_location_code:)
    location_field_name = location_field_name_for_type(location_type)

    new_location_record = if new_location_code.present?
                            Bibdata::FolioApiClient.instance.find_location_record(code: new_location_code)
                          end

    if new_location_code.present? && new_location_record.nil?
      raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update item record permanent location to '\
                                                        "\"#{new_location_code}\". Location code not found."
    end

    with_conflict_error_retry do
      item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: item_barcode)

      # No need to change location if it's already the location that we want
      return if item_record[location_field_name] == new_location_record&.fetch('id')

      payload = if new_location_code.blank?
                  # Item record with cleared permanent location value
                  item_record.except(location_field_name)
                else
                  # Item record with updated permanent location value
                  item_record.merge({ location_field_name => new_location_record['id'] })
                end

      self.put("/item-storage/items/#{item_record['id']}", payload)
    end
  rescue Faraday::Error => e
    raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update item record permanent location to '\
                                                      "\"#{new_location_code}\". "\
                                                      "FOLIO error message: #{e.response&.fetch(:body) || e.message}"
  end

  def update_item_parent_holdings_record_location(item_barcode:, location_type:, new_location_code:)
    location_field_name = location_field_name_for_type(location_type)

    if new_location_code.blank? && location_type == :permanent
      raise ArgumentError,
            'A holdings record permanent location cannot be blank.'
    end

    new_location_record = if new_location_code.present?
                            Bibdata::FolioApiClient.instance.find_location_record(code: new_location_code)
                          end

    if new_location_code.present? && new_location_record.nil?
      raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update holdings record permanent location to '\
                                                        "\"#{new_location_code}\". Location code not found."
    end

    with_conflict_error_retry do
      item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: item_barcode)
      holdings_record = Bibdata::FolioApiClient.instance.find_holdings_record(
        holdings_record_id: item_record['holdingsRecordId']
      )

      # No need to change location if it's already the location that we want
      return if holdings_record[location_field_name] == new_location_record&.fetch('id')

      payload = if new_location_code.blank?
                  # Holdings record with cleared permanent location value
                  holdings_record.except(location_field_name)
                else
                  # Holdings record with updated permanent location value
                  holdings_record.merge({ location_field_name => new_location_record['id'] })
                end
      self.put("/holdings-storage/holdings/#{holdings_record['id']}", payload)
    end
  rescue Faraday::Error => e
    raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update holdings record permanent location to '\
                                                      "\"#{new_location_code}\". "\
                                                      "FOLIO error message: #{e.response&.fetch(:body) || e.message}"
  end

  def clear_item_record_temporary_location(item_barcode:, location_type:, new_location_code:)
    location_field_name = location_field_name_for_type(location_type)

    new_location_record = if new_location_code.present?
                            Bibdata::FolioApiClient.instance.find_location_record(code: new_location_code)
                          end

    if new_location_code.present? && new_location_record.nil?
      raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update item record permanent location to '\
                                                        "\"#{new_location_code}\". Location code not found."
    end

    with_conflict_error_retry do
      item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: item_barcode)

      # No need to change location if it's already the location that we want
      return if item_record[location_field_name] == new_location_record&.fetch('id')

      payload = if new_location_code.blank?
                  # Item record with cleared permanent location value
                  item_record.except(location_field_name)
                else
                  # Item record with updated permanent location value
                  item_record.merge({ location_field_name => new_location_record['id'] })
                end

      self.put("/item-storage/items/#{item_record['id']}", payload)
    end
  rescue Faraday::Error => e
    raise Bibdata::Exceptions::LocationNotFoundError, 'Could not update item record permanent location to '\
                                                      "\"#{new_location_code}\". "\
                                                      "FOLIO error message: #{e.response[:body]}"
  end

  # Retry an operation muliple times if we run into an optimistic locking scenario due to an outdated record version.
  # This is indicated by a Faraday::ConflictError during a request.
  def with_conflict_error_retry(&block)
    Retriable.retriable(on: Faraday::ConflictError, tries: 3, base_interval: 3, multiplier: 1, &block)
  end
end
# rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
