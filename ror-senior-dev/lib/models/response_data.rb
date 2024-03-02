# frozen_string_literal: true

require 'json'

class ResponseData
  class << self
    def fetch
      file = File.read('./response.json')
      JSON.parse(file)
    end
  end
end
