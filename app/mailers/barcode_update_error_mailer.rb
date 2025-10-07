# frozen_string_literal: true

class BarcodeUpdateErrorMailer < ApplicationMailer
  def generate_email
    body_content = format_errors(params[:errors] || [])

    mail(
      to: Rails.configuration.bibdata['barcode_update_error_email_recipients'],
      subject: "Bibdata Error - Problem updating item record with barcode #{params[:barcode]}",
      body: body_content,
      content_type: 'text/plain'
    )
  end

  def format_errors(errors)
    content = "The following errors were encountered:\n\n"
    errors.each_with_index do |error, index|
      content += "#{index + 1}. #{error}\n"
    end
    content
  end
end
