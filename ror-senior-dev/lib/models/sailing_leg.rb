# frozen_string_literal: true

require 'rate_converter'
require 'date'

class SailingLeg
  VALID_ATTRS = %i[origin_port destination_port departure_date arrival_date sailing_code rate rate_currency].freeze

  attr_reader :origin_port, :destination_port, :sailing_code, :rate, :rate_currency

  def initialize(attrs)
    validate_attrs!(attrs)

    @origin_port = attrs['origin_port']
    @destination_port = attrs['destination_port']
    @sailing_code = attrs['sailing_code']
    @departure_date = attrs['departure_date']
    @arrival_date = attrs['arrival_date']
    @rate_currency = attrs['rate_currency']
    @rate = attrs['rate'].to_f
  end

  def departure_date
    format_date(@departure_date)
  end

  def arrival_date
    format_date(@arrival_date)
  end

  def duration
    arrival_date - departure_date
  end

  def rate_in_euro
    RateConverter.call(rate:, date: departure_date, rate_currency:, target_currency: 'EUR')
  end

  private

  def format_date(str_date)
    date = str_date.split('-')
    Date.new(date[0].to_i, date[1].to_i, date[2].to_i)
  end

  def validate_attrs!(attrs)
    raise ArgumentError, 'Invalid sailing attributes' unless attrs.keys.map(&:to_sym).all? do |k|
      VALID_ATTRS.include?(k)
    end
  end
end
