Rack::Attack.blocklist_ip("65.108.2.0/16")
Rack::Attack.blocklist_ip("23.22.35.0/16")
Rack::Attack.throttle("requests by ip", limit: 5, period: 2) do |request|
  request.ip
end
