class Bibdata::FolioApiClient < FolioApiClient
  def self.instance(reload: false)
    if @instance.nil? || reload
      @instance = self.new(FolioApiClient::Configuration.new(
        url: Rails.application.config.folio[:url],
        username: Rails.application.config.folio[:username],
        password: Rails.application.config.folio[:password],
        tenant: Rails.application.config.folio[:tenant],
        timeout: Rails.application.config.folio[:timeout],
      ))
    end
    @instance
  end

  # TODO: Probably want to move the methods below into the FolioApiClient gem

  def find_item_record(barcode:)
    item_search_results = self.get("/item-storage/items", { query: "barcode==#{barcode}", limit: 2 })["items"]
    return nil if item_search_results.length.zero?
    raise "Only expected one item with this barcode, but found more than one." if item_search_results.length > 1
    item_search_result = item_search_results[0]
    item_record_id = item_search_result["id"]
    self.get("/item-storage/items/#{item_record_id}")
  end

  def find_location_record(location_id:)
    self.get("/locations/#{location_id}")
  end

  def find_holdings_record(holdings_record_id:)
    self.get("/holdings-storage/holdings/#{holdings_record_id}")
  end

  def find_instance_record(instance_record_id:)
    self.get("/instance-storage/instances/#{instance_record_id}")
  end

  def find_marc_record(instance_record_id:)
    instance_record_source_response = self.get("/source-storage/source-records", { instanceId: instance_record_id })
    return nil if instance_record_source_response["totalRecords"].zero?
    bib_record_marc_hash = instance_record_source_response["sourceRecords"].first["parsedRecord"]["content"]
    MARC::Record.new_from_hash(bib_record_marc_hash)
  end
end
