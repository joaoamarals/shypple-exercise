# frozen_string_literal: true

require 'rate_converter'

class Sailing
  attr_reader :legs

  def initialize(legs)
    @legs = legs
  end

  def total_duration
    @legs.sum(&:duration)
  end

  def total_rate
    @legs.sum { |leg| rate_in_euro(leg) }
  end

  private

  def rate_in_euro(sailing)
    RateConverter.call(rate: sailing.rate, date: sailing.departure_date,
                       rate_currency: sailing.rate_currency, target_currency: 'EUR')
  end
end
