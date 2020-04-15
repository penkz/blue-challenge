# frozen_string_literal: true

# File: app.rb

require 'rspec'

# Parser Helper methods
module ParserHelpers
  CITIES = {
    'NYC' => 'New York City',
    'LA' => 'Los Angeles'
  }.freeze

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

# Parses comma separated values
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

# Parses dollar sign separated values
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

# Combines normalized data into a single array
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

# People Controller
class PeopleController
  def self.normalize(request_params)
    PeopleFactory.build(request_params)
  end
end

PeopleController.normalize(
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
)

# SPECS

# Specs for the People controller

RSpec.describe PeopleController do
  let(:request_params) do
    {
      comma: [
        'Mckayla, Atlanta, 5/29/1986',
        'Elliot, New York City, 4/3/1947',
        'Rodrigo, São Paulo, 4/3/2021'
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
      'Rigoberto New York City 12/1/1962',
      'Rodrigo São Paulo 4/3/2021'
    ]
  end

  describe '.normalize' do
    it 'returns an array with the normalized data' do
      expect(PeopleController.normalize(request_params)).to(
        match_array(expected_result)
      )
    end
  end
end

# Specs for the CommaParser
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
        expect(subject.parse).to match_array(expected_result)
      end
    end
  end
end

# Specs for the DollarSignParser
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
        expect(subject.parse).to match_array(expected_result)
      end
    end
  end
end

# Specs for the PeopleFactory
RSpec.describe PeopleFactory, focus: true do
  subject { PeopleFactory.build(data) }

  let(:dollar_data) do
    ['LA $ 10-4-1974 $ Nolan $ Rhiannon', 'NYC $ 12-1-1962 $ Bruen $ Rigoberto']
  end

  let(:comma_data) do
    ['Mckayla, Atlanta, 5/29/1986', 'Elliot, New York City, 4/3/1947']
  end

  let(:expected_comma_result) do
    ['Mckayla Atlanta 5/29/1986', 'Elliot New York City 4/3/1947']
  end

  let(:expected_dollar_result) do
    ['Rhiannon Los Angeles 10/4/1974', 'Rigoberto New York City 12/1/1962']
  end

  describe '.build' do
    context 'when only comma data is passed on the params' do
      let(:data) { { comma: comma_data } }
      it 'returns the parsed data' do
        expect(subject).to match_array(expected_comma_result)
      end
    end

    context 'when only dollar data is passed on the params' do
      let(:data) { { dollar: dollar_data } }
      it 'returns parsed data' do
        expect(subject).to match_array(expected_dollar_result)
      end
    end

    context 'when dollar and comma data is present' do
      let(:data) { { comma: comma_data, dollar: dollar_data } }
      it 'returns parsed data' do
        expect(subject).to match_array(
          expected_dollar_result + expected_comma_result
        )
      end
    end

    context 'when params is empty' do
      let(:data) { {} }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end
end
