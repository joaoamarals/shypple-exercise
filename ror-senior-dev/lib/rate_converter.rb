# frozen_string_literal: true

require 'models/response_data'

class RateConverter
  def self.call(rate:, date:, rate_currency:, target_currency:)
    new(rate:, date:, rate_currency:, target_currency:).call
  end

  def initialize(rate:, date:, rate_currency:, target_currency:)
    @rate = rate
    @date = date
    @rate_currency = rate_currency
    @target_currency = target_currency
  end

  def call
    return @rate if @rate_currency == @target_currency

    @rate * exchange_rate
  end

  private

  def exchange_rate
    exchange_rates[@date.to_s][@rate_currency.downcase].to_f
  end

  def exchange_rates
    ResponseData.fetch['exchange_rates']
  end
end
