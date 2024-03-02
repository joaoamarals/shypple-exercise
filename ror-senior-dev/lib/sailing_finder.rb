# frozen_string_literal: true

require 'json'
require 'byebug'
require 'date'

class SailingFinder
  class << self
    def call(origin:, destination:, criteria:, options: {})
      new(origin:, destination:, criteria:, options:).call
    end
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

  def find_fastest_sailing
    @requested_sailings = []

    find_sailings(origin: @requested_origin, sailings: fastest_connections)

    @requested_sailings.min_by { |sailing| total_duration(sailing) }
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

    sailings.min_by { |sailing| sailing_duration(sailing) }
  end

  def total_duration(sailing)
    sailing.reduce(0) { |sum, s| sum + sailing_duration(s) }
  end

  def sailing_duration(sailing)
    transform_date(sailing['arrival_date']) - transform_date(sailing['departure_date'])
  end

  def transform_date(str_date)
    date = str_date.split('-')
    Date.new(date[0].to_i, date[1].to_i, date[2].to_i)
  end

  def find_cheapest_sailing
    @requested_sailings = []

    find_sailings(origin: @requested_origin, sailings: cheapest_connections)

    @requested_sailings.min_by do |sailing|
      total_rate(sailing)
    end
  end

  def find_sailings(origin:, sailings:, uncompleted_sailings: [])
    return if max_legs_reached?

    from_origin = sailings.filter { |connection| connection['origin_port'] == origin }

    other_destinations = []

    from_origin.each do |sailing|
      if sailing['destination_port'] == @requested_destination
        @requested_sailings << [*uncompleted_sailings, sailing]
        next
      end

      other_destinations << sailing
    end

    other_destinations.each do |sailing|
      uncompleted_sailings << sailing
      find_sailings(origin: sailing['destination_port'], uncompleted_sailings:, sailings:)
    end
  end

  def total_rate(sailing)
    sailing.reduce(0) { |sum, s| sum + s['rate_in_euros'].to_f }
  end

  def max_legs_reached?
    return false unless @max_legs

    @requested_sailings.last&.size == @max_legs
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

  def find_cheapest_direct(origin:, destination:)
    sailings = direct_sailings(origin:, destination:)

    sailings = sailings.each { |sailing| add_rate_info(sailing) }
    sailings.min_by { |sailing| sailing['rate_in_euros'] }
  end

  def direct_sailings(origin:, destination:)
    sailings.filter { |sailing| sailing['origin_port'] == origin && sailing['destination_port'] == destination }
  end

  def add_rate_info(sailing)
    sailing_rate = rates.find { |rate| rate['sailing_code'] == sailing['sailing_code'] }
    sailing['rate'] = sailing_rate['rate']
    sailing['rate_currency'] = sailing_rate['rate_currency']
    sailing['rate_in_euros'] = rate_in_euros(sailing)
  end

  def rate_in_euros(sailing)
    return sailing['rate'] unless sailing['rate_currency'] != 'EUR'

    exchange_rate = exchange_rates[sailing['departure_date']]

    sailing['rate'] * exchange_rate[sailing['rate_currency'].downcase]
  end

  def all_origins
    sailings.map { |sailing| sailing['origin_port'] }.uniq
  end

  def all_destinations
    sailings.map { |sailing| sailing['destination_port'] }.uniq
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
