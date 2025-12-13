require 'rails_helper'

RSpec.describe LocationCleanupJob do
  let(:instance) { described_class.new }
  let(:barcode) { 'CU23392169' }

  describe '#perform' do
    it 'performs the expected operations' do
      expect(Bibdata::FolioApiClient.instance).to receive(:update_item_record_location).with(
        item_barcode: barcode,
        location_type: :permanent,
        new_location_code: nil
      )
      expect(Bibdata::FolioApiClient.instance).to receive(:update_item_record_location).with(
        item_barcode: barcode,
        location_type: :temporary,
        new_location_code: nil
      )
      expect(Bibdata::FolioApiClient.instance).to receive(:update_item_parent_holdings_record_location).with(
        item_barcode: barcode,
        location_type: :temporary,
        new_location_code: nil
      )
      instance.perform(barcode)
    end
  end
end
