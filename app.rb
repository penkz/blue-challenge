require 'rspec'
# frozen_string_literal: true

# File: app.rb

# WRITE YOUR CLASSES HERE

# Create two different parser, one for comma, and one for the dollar sign
# Each new parser class should have a parse method that will parse the given data
# Ater parsing both data, the two resulting arrays should be combined into one big array

Person = Struct.new(:first_name, :city, :birth_date) do
  def to_s
    "#{first_name} #{city} #{birth_date}"
  end
end

# Parser for the comma separated data
class CommaParser
  attr_reader :data, :result

  def initialize(data)
    @data = data
  end

  def parse
    return data if data.empty?

    personify.map(&:to_s)
  end

  private

  def parse_row(person)
    person.split(',').map(&:strip)
  end

  def personify
    result = []

    data.each do |row|
      info = parse_row(row)
      result << Person.new(info[0], info[1], info[2]).to_s
    end

    result
  end
end

# Parser for the dollar sign separated data
class DollarSignParser
end

class PeopleController
  def self.normalize(request_params)
    # TODO
    CommaParser.new(request_params[:comma]).parse
  end
end

PeopleController.normalize(
  {
    comma: [ # Fields: first name, city name, birth date
      'Mckayla, Atlanta, 5/29/1986',
      'Elliot, New York City, 4/3/1947'
    ],
    dollar: [ # Fields: city abbreviation, birth date, last name, first name
      'LA $ 10-4-1974 $ Nolan $ Rhiannon',
      'NYC $ 12-1-1962 $ Bruen $ Rigoberto'
    ]
  }
)

# SPECS

RSpec.describe 'PeopleController' do
  let(:request_params) do
    {
      comma: [
        'Mckayla, Atlanta, 5/29/1986',
        'Elliot, New York City, 4/3/1947'
      ],
      dollar: [
        'LA $ 10-4-1974 $ Nolan $ Rhiannon',
        'NYC $ 12-1-1962 $ Bruen $ Rigoberto'
      ]
    }
  end

  let(:expected_result) do
    [
      'Mckayla Atlanta 5/29/1986',
      'Elliot New York City 4/3/1947',
      'Rhiannon Los Angeles 10/4/1974',
      'Rigoberto New York City 12/1/1962'
    ]
  end

  describe '.normalize' do
    it 'returns an array with the normalized data' do
      expect(PeopleController.normalize(request_params)).to eq expected_result
    end
  end
end

RSpec.describe 'CommaParser' do
  subject { CommaParser.new(data) }
  let(:data) do
    ['Mckayla, Atlanta, 5/29/1986', 'Elliot, New York City, 4/3/1947']
  end

  let(:expected_result) do
    ['Mckayla Atlanta 5/29/1986', 'Elliot New York City 4/3/1947']
  end

  describe '#parse' do
    context 'when data is empty' do
      let(:data) { [] }
      it 'returns an empty array' do
        expect(subject.parse).to eq []
      end
    end

    context 'when data is not empty' do
      it 'returns an array with the parsed data' do
        expect(subject.parse).to eq expected_result
      end
    end
  end
end
