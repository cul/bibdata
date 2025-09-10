# frozen_string_literal: true

module Bibdata::Scsb
  def self.fetch_folio_records_associated_with_item(item_record)
    location_record = begin
      Bibdata::FolioApiClient.instance.find_location_record(location_id: item_record['permanentLocationId'])
    rescue Faraday::ResourceNotFound
      nil
    end

    holdings_record = Bibdata::FolioApiClient.instance.find_holdings_record(
      holdings_record_id: item_record['holdingsRecordId']
    )

    source_record = Bibdata::FolioApiClient.instance.find_source_record(
      instance_record_id: holdings_record['instanceId']
    )

    {
      location_record: location_record,
      holdings_record: holdings_record,
      source_record: source_record
    }
  end

  def self.merged_marc_record_for_barcode(barcode)
    item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: barcode)
    return nil if item_record.nil?

    fetch_folio_records_associated_with_item(item_record) => { location_record:, holdings_record:, source_record: }
    marc_record = MARC::Record.new_from_hash(source_record['parsedRecord']['content'])

    delete_866_field!(marc_record)
    replace_876_field!(marc_record, item_record, location_record, holdings_record['hrid'])
    replace_852_field!(marc_record, holdings_record, location_record)
    remove_fields_with_non_numeric_tags!(marc_record)

    # The commented-out section below is for generating spec fixture files to troubleshoot specific cases.
    # if Rails.env.development?
    #   Bibdata::FixtureHelper.write_records_to_fixture_dir(
    #     barcode, item_record, location_record, holdings_record, source_record, marc_record.to_xml.to_s
    #   )
    # end

    marc_record
  end

  # Returns the value if present, otherwise returns nil.
  def self.get_original_876_x_value(marc_record)
    marc_record.send(:[], '876')&.send(:[], 'x')
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L74
  def self.replace_852_field!(marc_record, folio_holdings_record, item_location_record) # rubocop:disable Metrics/AbcSize
    # Delete 852 field if present because we are going to generate our own
    marc_record.fields.delete_if { |f| f.tag == '852' }

    location_classification_part, location_item_part = folio_holdings_record['callNumber'].split(' ', 2)
    item_location_record_code = item_location_record&.fetch('code')

    subfields = [
      MARC::Subfield.new('0', folio_holdings_record['hrid']),
      item_location_record_code ? MARC::Subfield.new('b', item_location_record_code) : nil, # Location code
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
  def self.replace_876_field!(marc_record, folio_item_record, item_location_record, holdings_record_id)
    # Capture original 876 $x value before we delete the original 876 field
    original_marc_record_876_x_value = get_original_876_x_value(marc_record)

    # Delete 876 field if present because we are going to generate our own
    marc_record.fields.delete_if { |f| f.tag == '876' }
    marc_record.fields.concat(
      [
        MARC::DataField.new(
          '876', '0', '0',
          *subfields_for_876(
            folio_item_record, item_location_record, holdings_record_id, original_marc_record_876_x_value
          )
        )
      ]
    )
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L81
  def self.subfields_for_876(folio_item_record, item_location_record, holdings_record_id,
                             original_marc_record_876_x_value)
    # TODO: Find an example item record with enumeration and chronology to make sure these values are coming through.
    item_enumeration_and_chronology = [folio_item_record['enumeration'],
                                       folio_item_record['chronology']].compact.join(' ')

    [
      MARC::Subfield.new('0', holdings_record_id),
      MARC::Subfield.new('3', item_enumeration_and_chronology),
      MARC::Subfield.new('a', folio_item_record['hrid']),
      MARC::Subfield.new('p', folio_item_record['barcode']),
      MARC::Subfield.new('t', folio_item_record['copyNumber'] || '0')
    ] + recap_876_fields(folio_item_record, item_location_record, original_marc_record_876_x_value)
  end

  def self.collection_group_designation_for_item(folio_item_record, item_location_record,
                                                 original_marc_record_876_x_value)
    location_code = item_location_record&.fetch('code')
    barcode = folio_item_record['barcode']
    if Bibdata::Scsb::Constants::CGD_PRIVATE_LOCATION_CODES.include?(location_code)
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
  def self.recap_876_fields(folio_item_record, item_location_record, original_marc_record_876_x_value)
    collection_group_designation = collection_group_designation_for_item(folio_item_record, item_location_record,
                                                                         original_marc_record_876_x_value)

    # Use Restriction value is determined by CGD (Collection Use Designation) value
    use_restriction = case collection_group_designation
                      when Bibdata::Scsb::Constants::CGD_PRIVATE
                        Bibdata::Scsb::Constants::USE_RESTRICTION_SUPERVISED_USE
                      when Bibdata::Scsb::Constants::CGD_OPEN, Bibdata::Scsb::Constants::CGD_SHARED
                        '' # Blank value
                      end

    # For certain locations, we override the use restriction to enforce USE_RESTRICTION_IN_LIBRARY_USE
    if Bibdata::Scsb::Constants::USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODES.include?(
      item_location_record&.fetch('code')
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
