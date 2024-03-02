# frozen_string_literal: true

require 'json'
require 'byebug'
require 'date'
require 'models/sailing'
require 'rate_converter'

class SailingFinder
  def self.call(origin:, destination:, criteria:, options: {})
    new(origin:, destination:, criteria:, options:).call
  end

  def initialize(origin:, destination:, criteria:, options:)
    @requested_origin = origin
    @requested_destination = destination
    @criteria = criteria
    @max_legs = options[:direct] ? 1 : options[:max_legs]
  end

  def call
    if @criteria == 'cheapest'
      find_cheapest_sailing
    elsif @criteria == 'fastest'
      find_fastest_sailing
    end
  end

  private

  def find_cheapest_sailing
    @requested_sailing = []

    find_sailings(origin: @requested_origin, sailings: cheapest_connections)

    @requested_sailing.min_by { |sailing| total_rate(sailing) }
  end

  def find_fastest_sailing
    @requested_sailing = []

    find_sailings(origin: @requested_origin, sailings: fastest_connections)

    @requested_sailing.min_by { |sailing| total_duration(sailing) }
  end

  def fastest_connections
    fastest_connections = []

    all_origins.each do |origin|
      all_destinations.each do |destination|
        next if origin == destination

        sailing = find_fastest_direct(origin:, destination:)

        next unless sailing

        fastest_connections << sailing
      end
    end

    fastest_connections
  end

  def find_fastest_direct(origin:, destination:)
    sailings = direct_sailings(origin:, destination:)

    sailings.min_by(&:duration)
  end

  def find_sailings(origin:, sailings:, uncompleted_sailings: [])
    return if max_legs_reached?

    from_origin = sailings.filter { |sailing| sailing.origin_port == origin }

    other_destinations = []

    from_origin.each do |sailing|
      if sailing.destination_port == @requested_destination
        @requested_sailing << [*uncompleted_sailings, sailing]
        next
      end

      other_destinations << sailing
    end

    other_destinations.each do |sailing|
      uncompleted_sailings << sailing
      find_sailings(origin: sailing.destination_port, uncompleted_sailings:, sailings:)
    end
  end

  def total_rate(sailing)
    sailing.reduce(0) { |sum, s| sum + rate_in_euro(s) }
  end

  def total_duration(sailing)
    sailing.reduce(0) { |sum, s| sum + s.duration }
  end

  def max_legs_reached?
    return false unless @max_legs

    @requested_sailing.last&.size == @max_legs
  end

  def cheapest_connections
    cheapest_rates = []

    all_origins.each do |origin|
      all_destinations.each do |destination|
        next if origin == destination

        sailing = find_cheapest_direct(origin:, destination:)

        next unless sailing

        cheapest_rates << sailing
      end
    end

    cheapest_rates
  end

  def all_origins
    sailings.map(&:origin_port).uniq
  end

  def all_destinations
    sailings.map(&:destination_port).uniq
  end

  def find_cheapest_direct(origin:, destination:)
    sailings = direct_sailings(origin:, destination:)

    sailings.min_by { |sailing| rate_in_euro(sailing) }
  end

  def direct_sailings(origin:, destination:)
    sailings.filter { |sailing| sailing.origin_port == origin && sailing.destination_port == destination }
  end

  def rate_in_euro(sailing)
    RateConverter.call(rate: sailing.rate, date: sailing.departure_date,
                       rate_currency: sailing.rate_currency, target_currency: 'EUR')
  end

  # @return [Array<Sailing>]
  def sailings
    response_data['sailings'].map { |sailing_info| Sailing.new(add_rate_info(sailing_info)) }
  end

  def add_rate_info(sailing)
    sailing_rate = rates.find { |rate| rate['sailing_code'] == sailing['sailing_code'] }
    sailing['rate'] = sailing_rate['rate']
    sailing['rate_currency'] = sailing_rate['rate_currency']
    sailing
  end

  def rates
    response_data['rates']
  end

  def response_data
    file = File.read('./response.json')
    JSON.parse(file)
  end
end
