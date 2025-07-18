module Bibdata::Scsb
  CGD_PRIVATE = 'Private'
  CGD_SHARED = 'Shared'
  CGD_OPEN = 'Open' # NOTE: we don't actually ever send this value

  CGD_PRIVATE_LOCATION_CODES = [
    'avda',
    'off,avda',
    'avr4off',
    'bmcr4off',
    'off,bmcr',
    'off,avr',
    'off,bssc',
    'dic',
    'dic4off',
    'off,dic',
    'eaa4off',
    'off,eaa',
    'ean',
    'off,ean',
    'ear',
    'off,ear',
    'far',
    'far4off',
    'off,far',
    'off,hssc',
    'hsx',
    'off,hsx',
    'les',
    'off,les',
    'oral',
    'off,oral',
    'prd',
    'off,prd',
    'rbms',
    'off,rbms',
    'rbx',
    'rbx4off',
    'off,rbx',
    'uacl',
    'off,uacl',
    'unr',
    'off,unr',
    'uta',
    'off,uta',
    'utmrl',
    'off,utrml',
    'vmc',
    'off,vmc'
  ]

  CGD_PRIVATE_BARCODE_PREFIXES = [
    'RS',
    'AD',
    'HX',
    'UA',
    'UT'
  ]

  USE_RESTRICTION_IN_LIBRARY_USE = 'In Library Use'
  USE_RESTRICTION_SUPERVISED_USE = 'Supervised Use'
  USE_RESTRICTION_BLANK = ''

  # Any code in this list should result in an "In Library Use" Use Restriction value.
  USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODES = [
    'off,ave',
    'off,fax',
    'off,mrr',
    'off,msr',
    'off,mvr'
  ]

  def self.merged_marc_record_for_barcode(barcode)
    item_record = Bibdata::FolioApiClient.instance.find_item_record(barcode: barcode)

    return nil if item_record.nil?

    location_record = begin
      Bibdata::FolioApiClient.instance.find_location_record(location_id: item_record['permanentLocationId'])
    rescue Faraday::ResourceNotFound
      nil
    end

    # loan_type_record = Bibdata::FolioApiClient.instance.find_loan_type_record(loan_type_id: item_record["permanentLoanTypeId"])
    holdings_record = Bibdata::FolioApiClient.instance.find_holdings_record(holdings_record_id: item_record['holdingsRecordId'])
    # instance_record = Bibdata::FolioApiClient.instance.find_instance_record(instance_record_id: holdings_record["instanceId"])
    source_record = Bibdata::FolioApiClient.instance.find_source_record(instance_record_id: holdings_record['instanceId'])
    marc_record = MARC::Record.new_from_hash(source_record['parsedRecord']['content'])

    # The enrichment steps below are based on:
    # https://github.com/pulibrary/bibdata/blob/3e8888ce06944bb0fd0e3da7c13f603edf3d45a5/app/controllers/barcode_controller.rb#L25
    enrich_with_item!(marc_record, item_record, location_record, holdings_record['hrid'])
    enrich_with_holding!(marc_record, holdings_record, location_record)
    strip_non_numeric!(marc_record)

    # The section below is for generating spec fixture files to troubleshoot specific cases.
    # if Rails.env.development?
    #   Bibdata::FixtureHelper.write_records_to_fixture_dir(
    #     barcode, item_record, location_record, holdings_record, source_record, marc_record.to_xml.to_s
    #   )
    # end

    marc_record
  end

  def self.merged_marc_collection_xml_for_barcode(barcode)
    marc_record = self.merged_marc_record_for_barcode(barcode)
    return nil if marc_record.nil?

    # Wrap the marc record in a <collection> element and serialize to an xml string
    records_to_xml_collection_string([marc_record])
  end

  def self.valid_xml(xml_string)
    invalid_xml_range = /[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD]/
    xml_string.gsub(invalid_xml_range, '')
  end

  # Method below is based on:
  # https://github.com/pulibrary/bibdata/blob/8fc0ced129ef65b8b93930735352608804de8003/app/controllers/concerns/formatting_concern.rb#L6
  # @param records [MARC::Record] Could be one or a collection
  # @return [String] A serialized <mrx:record/> or <mrx:collection/>
  # "Cleans" the record of invalid xml characters
  def self.records_to_xml_collection_string(records)
    if records.is_a? Array
      xml_str = +'' # a "+string" is not frozen, even when the frozen_string_literal magic comment is present
      StringIO.open(xml_str) do |io|
        writer = MARC::XMLWriter.new(io)
        records.each { |r| writer.write(r) unless r.nil? }
        writer.close
      end
      valid_xml(xml_str)
    elsif records.is_a? String
      valid_xml(records)
    else
      valid_xml(records.to_xml.to_s)
    end
  end

  def self.enrich_with_holding!(marc_record, folio_holdings_record, item_location_record)
    delete_conflicting_holdings_data!(marc_record)
    marc_record.fields.concat(
      [
        generate_852(folio_holdings_record, item_location_record)
        # 866 field is optional for SCSB, and wasn't being sent before in CUL Voyager endpoint, so we'll skip this for now
        # generate_866(folio_holdings_record, item_location_record),
      ].flatten.compact
    )
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L74
  def self.generate_852(folio_holdings_record, item_location_record)
    location_classification_part, location_item_part = folio_holdings_record['callNumber'].split(' ', 2)
    item_location_record_code = item_location_record&.fetch('code')

    subfields = [
      MARC::Subfield.new('0', folio_holdings_record['hrid']),
      item_location_record_code ? MARC::Subfield.new('b', item_location_record_code) : nil, # Location code
      MARC::Subfield.new('h', location_classification_part), # Location classification part (from call number)
      MARC::Subfield.new('i', location_item_part)
    ].compact

    MARC::DataField.new(
      '852', '0', '0',
      *subfields
    )
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L31
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L74
  def self.enrich_with_item!(marc_record, folio_item_record, item_location_record, holdings_record_id)
    # Delete 876 field if present because we are going to generate our own
    marc_record.fields.delete_if { |f| f.tag == '876' }
    marc_record.fields.concat([
                                MARC::DataField.new('876', '0', '0',
                                                    *subfields_for_876(folio_item_record, item_location_record, holdings_record_id))
                              ])
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L81
  def self.subfields_for_876(folio_item_record, item_location_record, holdings_record_id)
    # TODO: Find an example item record with enumeration and chronology to make sure these values are coming through.
    item_enumeration_and_chronology = [folio_item_record['enumeration'],
                                       folio_item_record['chronology']].compact.join(' ')

    [
      MARC::Subfield.new('0', holdings_record_id),
      MARC::Subfield.new('3', item_enumeration_and_chronology),
      MARC::Subfield.new('a', folio_item_record['hrid']),
      MARC::Subfield.new('p', folio_item_record['barcode']),
      MARC::Subfield.new('t', folio_item_record['copyNumber'] || '0')
    ] + recap_876_fields(folio_item_record, item_location_record)
  end

  def self.collection_group_designation_for_item(folio_item_record, item_location_record)
    location_code = item_location_record&.fetch('code')
    barcode = folio_item_record['barcode']
    return CGD_PRIVATE if CGD_PRIVATE_LOCATION_CODES.include?(location_code)
    return CGF_PRIVATE if CGD_PRIVATE_BARCODE_PREFIXES.include?(barcode)

    CGD_SHARED
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/alma_item.rb#L91
  def self.recap_876_fields(folio_item_record, item_location_record)
    collection_group_designation = collection_group_designation_for_item(folio_item_record, item_location_record)

    # Use Restriction value is determined by CGD (Collection Use Designation) value
    use_restriction = case collection_group_designation
                      when CGD_PRIVATE
                        USE_RESTRICTION_SUPERVISED_USE
                      when CGD_OPEN, CGD_SHARED
                        '' # Blank value
                      end

    # For certain locations, we override the use restriction to enforce USE_RESTRICTION_IN_LIBRARY_USE
    if USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODES.include?(item_location_record&.fetch('code'))
      use_restriction = USE_RESTRICTION_IN_LIBRARY_USE_LOCATION_CODESZ
    end

    [
      # $x : Collection Group Designation -  The CGD is a designation given to an item by the partner institutions.  A private item will remain accessible only to patrons of the owning institution whereas the open and shared.  Designated items are available to be accessed by patrons of all partner institutions. The designation also changes based on certain criteria defined under the matching algorithm rules. <900> $a in SCSB Schema.
      # Possible values are:
      # - Private
      # - Shared
      # - Open (we always supply "Shared" for Open cases, and allow the SCSB system to change it to "Open" automatically when more than one copy of an item is held)
      # - Committed (not something we use at this time)
      # - Uncommittable (not something we use at this time)
      MARC::Subfield.new('x', collection_group_designation),

      # $h : Use Restriction - A value supplied by ILS at the time of accession. This is defined by the partners as to how their items are to be handled and if they need special care on how it is being lent to patrons.
      # Possible values are:
      # - Supervised Use - This might mean the item can be accessed only with special equipment in a specialized room under supervision.
      # - In Library Use - This would mean the item cannot be taken out of the library.
      # - Blank - This implies no restrictions. To further elaborate, blank would mean the <876> field and the $h subfield are present but blank.
      MARC::Subfield.new('h', use_restriction),

      # ReCAP status
      MARC::Subfield.new('j', folio_item_record['status']['name']),

      # $l : IMS Location Code
      MARC::Subfield.new('l', 'RECAP')
    ]
  end

  # This removes the bib record's 852s and 86Xs, to reduce confusion when holdings data is added.
  # Based on: https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L38
  def self.delete_conflicting_holdings_data!(marc_record)
    marc_record.fields.delete_if { |f| %w[852 866].include? f.tag }
  end

  # Based on:
  # https://github.com/pulibrary/bibdata/blob/4bcb0562fd9944266df834299ec4340cd3567a57/app/adapters/alma_adapter/marc_record.rb#L59
  def self.strip_non_numeric!(marc_record)
    marc_record.fields.delete_if do |field|
      # tag with non numeric character
      field.tag.scan(/^(\s|\D+)/).present?
    end
  end
end
