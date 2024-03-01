# frozen_string_literal: true
require 'json'

class SailingFinder
  class << self
    def call(origin:, destination:, criteria:, options:)
      new(origin:, destination:, criteria:, options:).call
    end
  end

  def initialize(origin:, destination:, criteria:, options:)
    @origin = origin
    @destination = destination
    @criteria = criteria
    @options = options
  end

  def call
    return unless @criteria == 'cheapest'

    find_cheapest(origin: @origin, destination: @destination)
  end

  private

  def direct_sailings(origin:, destination:)
    sailings.filter { |sailing| sailing['origin_port'] == origin && sailing['destination_port'] == destination }
  end

  def find_cheapest(origin:, destination:)
    sailings = direct_sailings(origin: origin, destination: destination) if @options[:direct]

    sailings = sailings.each { |sailing| add_rate_info(sailing) }
    sailings.min_by { |sailing| rate_in_euros(sailing) }
  end

  def add_rate_info(sailing)
    sailing_rate = rates.find { |rate| rate['sailing_code'] == sailing['sailing_code'] }
    sailing['rate'] = sailing_rate['rate']
    sailing['rate_currency'] = sailing_rate['rate_currency']
  end

  def rate_in_euros(sailing)
    return sailing['rate'] unless sailing['rate_currency'] != 'EUR'

    exchange_rate = exchange_rates[sailing['departure_date']]

    sailing['rate'] * exchange_rate[sailing['rate_currency'].downcase]
  end

  def find_cheapest_n_legs(origin, destination, leg)
    return if leg == 0



    {
      level_0: []
    }

  end

  def rates
    response_data['rates']
  end

  def exchange_rates
    response_data['exchange_rates']
  end

  def sailings
    response_data['sailings']
  end

  def response_data
    file = File.read('./response.json')
    JSON.parse(file)
  end
end
