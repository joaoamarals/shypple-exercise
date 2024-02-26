# frozen_string_literal: true

require './sailing_finder'

describe SailingFinder do
  let(:origin) { 'CNSHA' }
  let(:destination) { 'NLRTM' }

  it 'should find the cheapest direct sailing' do
    expected_result = [
      {
        "arrival_date" => "2022-03-05",
        "departure_date" => "2022-01-30",
        "destination_port" => "NLRTM",
        "origin_port" => "CNSHA",
        "rate" => "456.78",
        "rate_currency" => "USD",
        "sailing_code" => "MNOP",
      }
    ]

    result = described_class.call(origin:, destination:, criteria: 'cheapest', options: { direct: true })

    expect(result).to eq expected_result[0]
  end

  xit 'should find the cheapest sailing' do
    expected_result = [
      {
        "origin_port": 'CNSHA',
        "destination_port": 'ESBCN',
        "departure_date": '2022-01-29',
        "arrival_date": '2022-02-06',
        "sailing_code": 'ERXQ',
        "rate": '261.96',
        "rate_currency": 'EUR'
      },
      {
        "origin_port": 'ESBCN',
        "destination_port": 'NLRTM',
        "departure_date": '2022-02-16',
        "arrival_date": '2022-02-20',
        "sailing_code": 'ETRG',
        "rate": '69.96',
        "rate_currency": 'USD'
      }
    ]

    SailingFinder.call(criteria: 'cheapest')

    result == expected_result
  end

  xit 'should find the fastest sailing' do
    SailingFinder.call(criteria: 'fastest')
  end
end
