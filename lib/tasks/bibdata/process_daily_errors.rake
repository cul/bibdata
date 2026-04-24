# frozen_string_literal: true

namespace :bibdata do
  namespace :process_daily_errors do
    task email_barcode_update_errors: :environment do |t|
      # Collect error messages
      formatted_error_messages = []
      BarcodeUpdateError.where(
        notification_sent: false
      ).order(barcode: :asc, created_at: :asc).find_each(batch_size: 1000) do |barcode_update_error|
        formatted_error_messages << "#{barcode_update_error.barcode}: #{barcode_update_error.error_message} "\
                                    "(#{barcode_update_error.created_at.strftime('%Y-%m-%d')})"
      end

      # Send email notification about errors, if any errors exist
      if formatted_error_messages.present?
        # Send an email
        DailyErrorMailer.with(errors: formatted_error_messages).generate_email.deliver

        # Mark all notifications as sent
        BarcodeUpdateError.update_all(notification_sent: true) # rubocop:disable Rails/SkipsModelValidations
      else
        # If there aren't any errors, no need to send an email.
        Rails.logger.info(
          "Rake task #{t} skipped sending an email becuase there weren't any new notifications to send."
        )
      end

      # Delete any sent notifications that were created more than a week ago.
      # Reminder: delete_all skips ActiveRecord validations, but that's fine for this case.
      # NOTE: We're deleting in batches to avoid database timeouts, in case there are a lot of records to delete.
      BarcodeUpdateError.where(notification_sent: true, created_at: ..1.week.ago).in_batches(of: 1000).delete_all
    end
  end
end
