# frozen_string_literal: true

module Bibdata::Exceptions
  class BibdataError < StandardError; end

  class LocationNotFoundError < BibdataError; end
  class LocationUpdateError < BibdataError; end
  class UnresolvableHoldingsPermanentLocationError < BibdataError; end
end
