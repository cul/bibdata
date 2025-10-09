# frozen_string_literal: true

module Bibdata::Scsb
  def self.location_change_logger
    @location_change_logger ||= begin
      logger = ActiveSupport::Logger.new(Rails.root.join("log/#{Rails.env}-location-changes.log"))
      logger.level = Rails.logger.level # Match rails application log level
      logger
    end
  end

  def self.fetch_folio_records_associated_with_item(item_record)
    holdings_record = Bibdata::FolioApiClient.instance.find_holdings_record(
      holdings_record_id: item_record['holdingsRecordId']
    )

    holdings_permanent_location_record = Bibdata::FolioApiClient.instance.find_location_record(
      location_id: holdings_record['permanentLocationId']
    )

    source_record = Bibdata::FolioApiClient.instance.find_source_record(
      instance_record_id: holdings_record['instanceId']
    )

    material_type_record = Bibdata::FolioApiClient.instance.find_material_type_record(
      material_type_id: item_record['materialTypeId']
    )

    {
      holdings_record: holdings_record,
      holdings_permanent_location_record: holdings_permanent_location_record,
      source_record: source_record,
      material_type_record: material_type_record
    }
  end

  def self.merged_marc_record_for_barcode(barcode, flip_location:)
    item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: barcode)
    return nil if item_record.nil?

    fetch_folio_records_associated_with_item(item_record) => {
      holdings_record:, holdings_permanent_location_record:, source_record:, material_type_record:
    }

    current_holdings_permanent_location_code = holdings_permanent_location_record&.fetch('code')

    # This is unlikely to happen, but we're accounting for it just in case someone deletes a FOLIO location
    # that is referenced by the holdings record.
    if current_holdings_permanent_location_code.nil?
      raise Bibdata::Exceptions::UnresolvableHoldingsPermanentLocationError,
            'Could not determine the parent holdings permanent location.'
    end

    if flip_location
      perform_location_flip!(
        barcode, item_record, holdings_record,
        current_holdings_permanent_location_code, material_type_record&.fetch('name')
      )

      # After performing a flip, invoke this method again with `flip_location: false` to retrieve the latest updated
      # data from FOLIO, and then return the result.  This is a little slower than modifying the records we already
      # have in memory, but it's simpler and guarantees that we're serving the latest versions from FOLIO.
      return merged_marc_record_for_barcode(barcode, flip_location: false)
    end

    marc_record = MARC::Record.new_from_hash(source_record['parsedRecord']['content'])
    enhance_base_marc_record!(marc_record, item_record, holdings_record, current_holdings_permanent_location_code)

    marc_record
  end

  def self.enhance_base_marc_record!(
    marc_record, item_record, holdings_record, current_holdings_permanent_location_code
  )
    delete_866_field!(marc_record)
    replace_876_field!(marc_record, item_record, current_holdings_permanent_location_code, holdings_record['hrid'])
    replace_852_field!(marc_record, holdings_record, current_holdings_permanent_location_code)
    remove_fields_with_non_numeric_tags!(marc_record)
  end

  def self.perform_location_flip!(
    barcode, item_record, holdings_record, current_holdings_permanent_location_code, material_type_name
  )
    # If the current holdings permanent location does not equal the desired flipped location,
    # update the holdings record permanent location to the flipped location.
    update_holdings_permanent_location_if_required!(
      barcode, current_holdings_permanent_location_code, material_type_name
    )

    # If this item record has a permanent location, we want to clear it.
    clear_item_permanent_location_if_present!(barcode, item_record)

    # If this record has a holdings temporary location or item temporary location,
    # send a notification email because assignment of temporary locations is
    # undesirable for us and that needs to be manually corrected.
    send_notification_email_if_temporary_locations_found(barcode, item_record, holdings_record)
  end

  # rubocop:disable Metrics/AbcSize
  def self.update_holdings_permanent_location_if_required!(
    barcode, current_holdings_permanent_location_code, material_type_name
  )
    flipped_location_code = Bibdata::OffsiteLocationFlipper.location_code_to_recap_flipped_location_code(
      current_holdings_permanent_location_code, barcode, material_type_name
    )

    if flipped_location_code.nil?
      error_message = 'Unable to map current location to flipped location '\
                      "(location code: #{current_holdings_permanent_location_code}, barcode: #{barcode}, "\
                      "material type: #{material_type_name}).  Maybe a new mapping rule is needed?"
      self.location_change_logger.unknown("#{barcode}: #{error_message}")
      BarcodeUpdateErrorMailer.with(barcode: barcode, errors: [error_message]).generate_email.deliver
      return
    end

    if current_holdings_permanent_location_code == flipped_location_code
      self.location_change_logger.unknown(
        "#{barcode}: No holdings permanent location flip needed. "\
        "Current value is: #{current_holdings_permanent_location_code}"
      )
      return
    end

    self.location_change_logger.unknown(
      "#{barcode}: Trying to change parent holdings permanent location from "\
      "#{current_holdings_permanent_location_code} to #{flipped_location_code}"
    )
    Bibdata::FolioApiClient.instance.update_item_parent_holdings_record_permanent_location(
      item_barcode: barcode, location_type: :permanent, new_location_code: flipped_location_code
    )
    self.location_change_logger.unknown(
      "#{barcode}: Changed parent holdings permanent location from "\
      "#{current_holdings_permanent_location_code} to #{flipped_location_code}"
    )
  rescue Bibdata::Exceptions::LocationNotFoundError => e
    # This error will come up in one of two cases:
    #
    # 1) There is a mistake in the Bibdata::OffsiteLocationFlipper location mapping logic
    # and it references a flipped location code that does not exist in FOLIO.
    # or
    # 2) The Bibdata::OffsiteLocationFlipper location mapping was correct at some point,
    # but a location code in FOLIO was unexpectedly changed and we either need to update
    # the location mapping logic or reinstate the old location code in FOLIO.
    #
    # When this error comes up, we'll just log and send an email notification about it.
    # We don't need the error to interrupt the rest of the overall process, and we'll
    # intentionally leave the holdings location unmodified.
    self.location_change_logger.unknown("Barcode #{barcode}: #{e.message}")
    BarcodeUpdateErrorMailer.with(barcode: barcode, errors: [e.message]).generate_email.deliver
  end
  # rubocop:enable Metrics/AbcSize

  def self.clear_item_permanent_location_if_present!(barcode, item_record)
    return if item_record['permanentLocationId'].blank?

    self.location_change_logger.unknown(
      "#{barcode}: Trying to clear item permanent location "\
      "(was originally FOLIO location #{item_record['permanentLocationId']})"
    )
    Bibdata::FolioApiClient.instance.update_item_record_permanent_location(
      item_barcode: barcode, location_type: :permanent, new_location_code: nil
    )
    self.location_change_logger.unknown(
      "#{barcode}: Cleared item permanent location "\
      "(was originally FOLIO location #{item_record['permanentLocationId']})"
    )
  end

  def self.send_notification_email_if_temporary_locations_found(
    barcode, item_record, holdings_record
  )
    temporary_location_notification_messages = []
    if item_record['temporaryLocationId'].present?
      error_message = 'Found unwanted item temporary location.'
      self.location_change_logger.unknown("#{barcode}: #{error_message}")
      temporary_location_notification_messages << error_message
    end
    if holdings_record['temporaryLocationId'].present?
      error_message = 'Found unwanted parent holdings temporary location.'
      self.location_change_logger.unknown("#{barcode}: #{error_message}")
      temporary_location_notification_messages << error_message
    end

    return if temporary_location_notification_messages.empty?

    BarcodeUpdateErrorMailer.with(
      barcode: barcode, errors: temporary_location_notification_messages
    ).generate_email.deliver
  end

  # Returns the value if present, otherwise returns nil.
  def self.get_original_876_x_value(marc_record)
    marc_record.send(:[], '876')&.send(:[], 'x')
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L74
  def self.replace_852_field!(marc_record, folio_holdings_record, holdings_permanent_location_code)
    # Delete 852 field if present because we are going to generate our own
    marc_record.fields.delete_if { |f| f.tag == '852' }

    location_classification_part, location_item_part = folio_holdings_record['callNumber'].split(' ', 2)

    subfields = [
      MARC::Subfield.new('0', folio_holdings_record['hrid']),
      MARC::Subfield.new('b', holdings_permanent_location_code),
      MARC::Subfield.new('h', location_classification_part), # Location classification part (from call number)
      MARC::Subfield.new('i', location_item_part)
    ].compact

    marc_record.fields.concat(
      [
        MARC::DataField.new(
          '852', '0', '0',
          *subfields
        )
      ].flatten.compact
    )
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L31
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L74
  def self.replace_876_field!(marc_record, folio_item_record, holdings_permanent_location_code, holdings_record_hrid)
    # Capture original 876 $x value before we delete the original 876 field
    original_marc_record_876_x_value = get_original_876_x_value(marc_record)

    # Delete 876 field if present because we are going to generate our own
    marc_record.fields.delete_if { |f| f.tag == '876' }
    marc_record.fields.concat(
      [
        MARC::DataField.new(
          '876', '0', '0',
          *subfields_for_876(
            folio_item_record, holdings_permanent_location_code, holdings_record_hrid, original_marc_record_876_x_value
          )
        )
      ]
    )
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L81
  def self.subfields_for_876(folio_item_record, holdings_permanent_location_code, holdings_record_hrid,
                             original_marc_record_876_x_value)
    # TODO: Find an example item record with enumeration and chronology to make sure these values are coming through.
    item_enumeration_and_chronology = [folio_item_record['enumeration'],
                                       folio_item_record['chronology']].compact.join(' ')

    [
      MARC::Subfield.new('0', holdings_record_hrid),
      MARC::Subfield.new('3', item_enumeration_and_chronology),
      MARC::Subfield.new('a', folio_item_record['hrid']),
      MARC::Subfield.new('p', folio_item_record['barcode']),
      MARC::Subfield.new('t', folio_item_record['copyNumber'] || '0')
    ] + recap_876_fields(folio_item_record, holdings_permanent_location_code, original_marc_record_876_x_value)
  end

  def self.collection_group_designation_for_item(folio_item_record, holdings_permanent_location_code,
                                                 original_marc_record_876_x_value)
    barcode = folio_item_record['barcode']
    if Bibdata::Scsb::Constants::CGD_PRIVATE_LOCATION_CODES.include?(holdings_permanent_location_code)
      return Bibdata::Scsb::Constants::CGD_PRIVATE
    end
    if Bibdata::Scsb::Constants::CGD_PRIVATE_BARCODE_PREFIXES.include?(barcode)
      return Bibdata::Scsb::Constants::CGD_PRIVATE
    end

    # If none of the above conditions resulted in an early exit from this method,
    # and the original marc record's 876 $x was 'Committed', then return a CGD value of 'Committed'.
    if original_marc_record_876_x_value == Bibdata::Scsb::Constants::CGD_COMMITTED
      return Bibdata::Scsb::Constants::CGD_COMMITTED
    end

    Bibdata::Scsb::Constants::CGD_SHARED
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L91
  def self.recap_876_fields(folio_item_record, holdings_permanent_location_code, original_marc_record_876_x_value)
    collection_group_designation = collection_group_designation_for_item(
      folio_item_record, holdings_permanent_location_code, original_marc_record_876_x_value
    )

    # Use Restriction value is determined by CGD (Collection Use Designation) value
    use_restriction = case collection_group_designation
                      when Bibdata::Scsb::Constants::CGD_PRIVATE
                        Bibdata::Scsb::Constants::USE_RESTRICTION_SUPERVISED_USE
                      when Bibdata::Scsb::Constants::CGD_OPEN, Bibdata::Scsb::Constants::CGD_SHARED
                        '' # Blank value
                      end

    # For certain locations, we override the use restriction to enforce USE_RESTRICTION_IN_LIBRARY_USE
    if Bibdata::Scsb::Constants::USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODES.include?(
      holdings_permanent_location_code
    )
      use_restriction = Bibdata::Scsb::Constants::USE_RESTRICTION_IN_LIBRARY_USE
    end

    [
      # $x : Collection Group Designation -  The CGD is a designation given to an item by the partner institutions.
      #                                      A private item will remain accessible only to patrons of the owning
      #                                      institution whereas the open and shared.  Designated items are available
      #                                      to be accessed by patrons of all partner institutions. The designation
      #                                      also changes based on certain criteria defined under the matching algorithm
      #                                      rules. <900> $a in SCSB Schema.
      # Possible values are:
      # - Private
      # - Shared
      # - Open (we always supply "Shared" for Open cases, and allow the SCSB system to change it to "Open" automatically
      #   when more than one copy of an item is held)
      # - Committed (not something we use at this time)
      # - Uncommittable (not something we use at this time)
      MARC::Subfield.new('x', collection_group_designation),

      # $h : Use Restriction - A value supplied by ILS at the time of accession. This is defined by the partners as to
      #                        how their items are to be handled and if they need special care on how it is being lent
      #                        to patrons.
      # Possible values are:
      # - Supervised Use - This might mean the item can be accessed only with special equipment in
      #                    a specialized room under supervision.
      # - In Library Use - This would mean the item cannot be taken out of the library.
      # - Blank - This implies no restrictions. To further elaborate, blank would mean the <876> field and the $h
      #           subfield are present but blank.
      MARC::Subfield.new('h', use_restriction),

      # ReCAP status
      MARC::Subfield.new('j', folio_item_record['status']['name']),

      # $l : IMS Location Code
      MARC::Subfield.new('l', 'RECAP')
    ]
  end

  # This removes the bib record's 866 fields, to reduce confusion when we add other holdings data in a separate step.
  # Based on: https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L38
  def self.delete_866_field!(marc_record)
    marc_record.fields.delete_if { |f| %w[866].include? f.tag }
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L59
  def self.remove_fields_with_non_numeric_tags!(marc_record)
    marc_record.fields.delete_if do |field|
      # tag with non numeric character
      field.tag.scan(/^(\s|\D+)/).present?
    end
  end
end
