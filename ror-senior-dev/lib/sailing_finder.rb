# frozen_string_literal: true

require 'models/sailing'
require 'models/sailing_leg'
require 'models/response_data'

# Find a sailing for an origin/destination based on a given criteria ['cheapest', 'fastest']
# and some options [:max_legs, :direct]
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

    set_requested_sailings(origin: @requested_origin, available_legs: cheapest_connections)

    @requested_sailing.min_by(&:total_rate)
  end

  def find_fastest_sailing
    @requested_sailing = []

    set_requested_sailings(origin: @requested_origin, available_legs: fastest_connections)

    @requested_sailing.min_by(&:total_duration)
  end

  def set_requested_sailings(origin:, available_legs:, uncompleted_sailings: [])
    return if max_legs_reached?

    from_origin = available_legs.select { |leg| leg.origin_port == origin }

    other_destinations = from_origin.reduce([]) do |acc, sailing_leg|
      if sailing_leg.destination_port == @requested_destination
        @requested_sailing << Sailing.new([*uncompleted_sailings, sailing_leg])
        next acc
      end

      acc << sailing_leg
    end

    other_destinations.each do |sailing_leg|
      set_requested_sailings(origin: sailing_leg.destination_port, uncompleted_sailings: [sailing_leg], available_legs:)
    end
  end

  def max_legs_reached?
    return false unless @max_legs
    return false unless @requested_sailing.any?

    @requested_sailing.max_by { |s| s.legs.size }.legs.size == @max_legs
  end

  def fastest_connections
    build_od_matrix_by do |origin:, destination:|
      fastest_direct_leg(origin:, destination:)
    end
  end

  def cheapest_connections
    build_od_matrix_by do |origin:, destination:|
      cheapest_direct_leg(origin:, destination:)
    end
  end

  def build_od_matrix_by
    matrix = []

    available_origins.each do |origin|
      available_destinations.each do |destination|
        next if origin == destination

        sailing = yield(origin:, destination:)

        next unless sailing

        matrix << sailing
      end
    end

    matrix
  end

  def fastest_direct_leg(origin:, destination:)
    sailings = sailing_legs_for(origin:, destination:)

    sailings.min_by(&:duration)
  end

  def cheapest_direct_leg(origin:, destination:)
    sailing_legs_for(origin:, destination:).min_by(&:rate_in_euro)
  end

  def available_origins
    sailing_legs.map(&:origin_port).uniq
  end

  def available_destinations
    sailing_legs.map(&:destination_port).uniq
  end

  def sailing_legs_for(origin:, destination:)
    sailing_legs.select { |sailing| sailing.origin_port == origin && sailing.destination_port == destination }
  end

  # @return [Array<Sailing>]
  def sailing_legs
    response_data['sailings'].map { |sailing_info| SailingLeg.new(add_rate_info(sailing_info)) }
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
    ResponseData.fetch
  end
end
