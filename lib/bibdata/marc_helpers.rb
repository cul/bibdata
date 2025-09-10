# frozen_string_literal: true

module Bibdata::MarcHelpers
  # def self.merged_marc_collection_xml_for_barcode(barcode)
  def self.render_marc_records_as_marc_collection_xml(marc_records)
    marc_records = Array.wrap(marc_records)
    return nil if marc_records.blank?

    # Wrap the marc record in a <collection> element and serialize to an xml string
    records_to_xml_collection_string(marc_records)
  end

  # Method below is based on:
  # https://github.com/pulibrary/bibdata/blob/8fc0ced129ef65b8b93930735352608804de8003/app/controllers/concerns/formatting_concern.rb#L6
  # @param records [MARC::Record] Could be one or a collection
  # @return [String] A serialized <mrx:record/> or <mrx:collection/>
  # "Cleans" the record of invalid xml characters
  def self.records_to_xml_collection_string(records) # rubocop:disable Metrics/MethodLength
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

  def self.valid_xml(xml_string)
    invalid_xml_range = /[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD]/
    xml_string.gsub(invalid_xml_range, '')
  end
end
