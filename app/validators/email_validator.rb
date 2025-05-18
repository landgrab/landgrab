# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if email_valid?(value)

    record.errors.add(attribute, options[:message] || 'must be a valid email address')
  end

  def email_valid?(value)
    # validation regex from https://stackoverflow.com/a/1189163/1323144
    value.match?(/\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/)
  end
end
