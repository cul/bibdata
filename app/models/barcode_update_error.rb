# frozen_string_literal: true

class BarcodeUpdateError < ApplicationRecord
  validates :barcode, :error_message, presence: true
  validates :notification_sent, inclusion: { in: [true, false], message: 'must be a boolean value' }
end
