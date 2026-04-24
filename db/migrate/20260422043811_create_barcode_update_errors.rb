class CreateBarcodeUpdateErrors < ActiveRecord::Migration[8.0]
  def change
    create_table :barcode_update_errors do |t|
      t.string :barcode, null: false, index: true
      t.string :error_message, null: false
      t.boolean :notification_sent, null: false, default: false, index: true

      t.timestamps
    end

    add_index :barcode_update_errors, [:barcode, :created_at] # For daily error aggregation email notifications
    add_index :barcode_update_errors, [:notification_sent, :created_at] # For daily cleanup of older errors
  end
end
