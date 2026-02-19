# frozen_string_literal: true

require "httparty"

# Simple utility to check if an external URL is reachable.
# Used for monitoring external service health from admin dashboard.
#
# NOTE: This trivial HTTParty usage could be replaced with Net::HTTP:
#   uri = URI.parse(url)
#   response = Net::HTTP.get_response(uri)
#   response.code.to_i == 200
module ExternalHealthCheck
  def self.reachable?(url)
    response = HTTParty.get(url, timeout: 5)
    response.code == 200
  rescue StandardError
    false
  end
end
