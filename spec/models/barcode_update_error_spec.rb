require 'rails_helper'

RSpec.describe BarcodeUpdateError, type: :model do
  let(:barcode) { 'AR03426424' }
  let(:error_message) { 'This is an error message.' }
  let(:instance) { described_class.create(barcode: barcode, error_message: error_message) }

  it "successfully creates an instance" do
    expect(instance).to be_a(BarcodeUpdateError)
    expect(instance.barcode).to eq(barcode)
    expect(instance.error_message).to eq(error_message)
  end

  it "a new instance sets notification_sent to false by default" do
    expect(instance.notification_sent).to eq(false)
  end

  context "validations" do
    it "requires a barcode to be present" do
      instance.barcode = nil
      expect(instance.save).to eq(false)
      expect(instance.errors[:barcode]).to eq(["can't be blank"])
    end

    it "requires an error_message to be present" do
      instance.error_message = nil
      expect(instance.save).to eq(false)
      expect(instance.errors[:error_message]).to eq(["can't be blank"])
    end

    it "requires notification_sent to be a boolean value" do
      instance.notification_sent = nil
      expect(instance.save).to eq(false)
      expect(instance.errors[:notification_sent]).to eq(['must be a boolean value'])
    end
  end
end
