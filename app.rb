# frozen_string_literal: true

# File: app.rb

require 'rspec'
require 'pry-byebug'

CITIES = {
  'NYC' => 'New York City',
  'LA' => 'Los Angeles'
}.freeze

# Some parser helper methods
module ParserHelpers
  def replace_dash_with_fwdslash(str)
    str.gsub('-', '/')
  end

  def get_city_from_abbr(city)
    CITIES.fetch(city, 'Not available')
  end
end

Person = Struct.new(:first_name, :city, :birth_date) do
  def to_s
    "#{first_name} #{city} #{birth_date}"
  end
end

# Parser for the comma separated values
class CommaParser
  attr_reader :data

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
      result << Person.new(info[0], info[1], info[2])
    end

    result
  end
end

# Parser for the dollar sign separated values
class DollarSignParser
  include ParserHelpers

  attr_reader :data
  def initialize(data)
    @data = data
  end

  def parse
    return data if data.empty?

    personify.map(&:to_s)
  end

  private

  def parse_row(person)
    person.split('$').map(&:strip)
  end

  def personify
    result = []

    data.each do |row|
      info = parse_row(row)
      city = get_city_from_abbr(info[0])
      birth_date = replace_dash_with_fwdslash(info[1])
      result << Person.new(info[3], city, birth_date)
    end

    result
  end
end

class PeopleFactory
  PARSERS = {
    comma: CommaParser,
    dollar: DollarSignParser
  }.freeze

  def self.build(params)
    result = []
    params.each do |k, v|
      result += PARSERS[k].new(v).parse
    end

    result
  end
end

class PeopleController
  def self.normalize(request_params)
    PeopleFactory.build(request_params)
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

RSpec.describe PeopleController do
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

RSpec.describe CommaParser do
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

RSpec.describe DollarSignParser do
  subject { DollarSignParser.new(data) }
  let(:data) do
    ['LA $ 10-4-1974 $ Nolan $ Rhiannon', 'NYC $ 12-1-1962 $ Bruen $ Rigoberto']
  end

  let(:expected_result) do
    ['Rhiannon Los Angeles 10/4/1974', 'Rigoberto New York City 12/1/1962']
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
