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
    response_data['exchange_rates']
  end

  def response_data
    file = File.read('./response.json')
    JSON.parse(file)
  end
end
