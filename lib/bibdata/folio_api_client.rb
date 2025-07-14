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
end
