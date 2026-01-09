# frozen_string_literal: true

MoneyRails.configure do |config|
  config.default_currency = :gbp

  config.no_cents_if_whole = false
end

Money.locale_backend = :i18n
