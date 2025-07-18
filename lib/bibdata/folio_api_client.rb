# frozen_string_literal: true

class Bibdata::FolioApiClient < FolioApiClient
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
end
