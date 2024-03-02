# frozen_string_literal: true

require 'sailing_finder'

RSpec.describe SailingFinder do
  let(:origin) { 'CNSHA' }
  let(:destination) { 'NLRTM' }

  context 'when the criteria is the cheapest' do
    let(:criteria) { 'cheapest' }

    it 'should find the cheapest sailing' do
      expected_result = [
        {
          'origin_port' => 'CNSHA',
          'destination_port' => 'ESBCN',
          'departure_date' => '2022-01-29',
          'arrival_date' => '2022-02-06',
          'sailing_code' => 'ERXQ',
          'rate' => '261.96',
          'rate_currency' => 'EUR'
        },
        {
          'origin_port' => 'ESBCN',
          'destination_port' => 'NLRTM',
          'departure_date' => '2022-02-16',
          'arrival_date' => '2022-02-20',
          'sailing_code' => 'ETRG',
          'rate' => '69.96',
          'rate_currency' => 'USD'
        }
      ]

      result = described_class.call(origin:, destination:, criteria: 'cheapest')

      expect(result.map(&:sailing_code)).to eq(expected_result.map { |el| el['sailing_code'] })
    end

    context 'and direct sailings' do
      it 'should find the cheapest direct' do
        expected_result = [
          {
            'arrival_date' => '2022-03-05',
            'departure_date' => '2022-01-30',
            'destination_port' => 'NLRTM',
            'origin_port' => 'CNSHA',
            'rate' => '456.78',
            'rate_currency' => 'USD',
            'sailing_code' => 'MNOP'
          }
        ]

        result = described_class.call(origin:, destination:, criteria:, options: { direct: true })

        expect(result.map(&:sailing_code)).to eq(expected_result.map { |el| el['sailing_code'] })
      end
    end

    context 'and a defined maximum legs' do
      it 'should find the cheapest with a maximum of 1 leg', :aggregate_failures do
        expected_result = [
          {
            'arrival_date' => '2022-03-05',
            'departure_date' => '2022-01-30',
            'destination_port' => 'NLRTM',
            'origin_port' => 'CNSHA',
            'rate' => '456.78',
            'rate_currency' => 'USD',
            'sailing_code' => 'MNOP'
          }
        ]

        result = described_class.call(origin:, destination:, criteria:, options: { direct: true })

        expect(result.size).to be <= 1
        expect(result.map(&:sailing_code)).to eq(expected_result.map { |el| el['sailing_code'] })
      end

      it 'should find the cheapest with a maximum of 2 legs', :aggregate_failures do
        expected_result = [
          {
            'origin_port' => 'CNSHA',
            'destination_port' => 'ESBCN',
            'departure_date' => '2022-01-29',
            'arrival_date' => '2022-02-06',
            'sailing_code' => 'ERXQ',
            'rate' => '261.96',
            'rate_currency' => 'EUR'
          },
          {
            'origin_port' => 'ESBCN',
            'destination_port' => 'NLRTM',
            'departure_date' => '2022-02-16',
            'arrival_date' => '2022-02-20',
            'sailing_code' => 'ETRG',
            'rate' => '69.96',
            'rate_currency' => 'USD'
          }
        ]

        result = described_class.call(origin:, destination:, criteria:, options: { max_legs: 2 })

        expect(result.size).to be <= 2
        expect(result.map(&:sailing_code)).to eq(expected_result.map { |el| el['sailing_code'] })
      end

      context 'when the origin is not reachable' do
        let(:origin) { 'ZZZZZ' }

        it 'should not return' do
          result = described_class.call(origin:, destination:, criteria:)

          expect(result).to be_nil
        end
      end

      context 'when the destination is not reachable' do
        let(:destination) { 'ZZZZZ' }

        it 'should not return' do
          result = described_class.call(origin:, destination:, criteria:)

          expect(result).to be_nil
        end
      end
    end
  end

  context 'when the criteria is the fastest' do
    let(:criteria) { 'fastest' }

    it 'should find the fastest sailing' do
      expected_result = [
        {
          'origin_port' => 'CNSHA',
          'destination_port' => 'NLRTM',
          'departure_date' => '2022-01-29',
          'arrival_date' => '2022-02-15',
          'sailing_code' => 'QRST'
        }
      ]

      result = SailingFinder.call(origin:, destination:, criteria:)

      expect(result.map(&:sailing_code)).to eq(expected_result.map { |el| el['sailing_code'] })
    end
  end
end
