class Rack::Attack
  blocklist_ip("65.108.2.0/16")
  blocklist_ip("23.22.35.0/16")
  blocklist_ip("3.224.220.0/16")

  throttle("requests by ip", limit: 10, period: 2.seconds) do |request|
    request.ip unless request.path.start_with?('/assets')
  end

  blocklist('pentesters') do |req|
    req.path.include?('/etc/passwd') ||
    req.path.include?('wp-admin') ||
    req.path.include?('wp-login')
    # Rails.cache.write("block 1.2.3.4", true, expires_in: 2.hours)
    # Rails.cache.read("block #{req.ip}")
  end
end