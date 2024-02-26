# frozen_string_literal: true

it 'should find the cheapest direct sailing' do
  expected_result = [
    {
      "origin_port": 'CNSHA',
      "destination_port": 'NLRTM',
      "departure_date": '2022-02-01',
      "arrival_date": '2022-03-01',
      "sailing_code": 'ABCD',
      "rate": '589.30',
      "rate_currency": 'USD'
    }
  ]

  RouteFinder.call(criteria: 'cheapest', options: { direct: true })

  result == expected_result
end

it 'should find the cheapest sailing' do
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

  RouteFinder.call(criteria: 'cheapest')

  result == expected_result
end

it 'should find the fastest sailing' do
  RouteFinder.call(criteria: 'fastest')
end
