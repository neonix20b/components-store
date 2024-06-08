class Rack::Attack
  blocklist_ip("65.108.2.0/16")
  blocklist_ip("23.22.35.0/16")
  blocklist_ip("3.224.220.0/16")

  throttle("requests by ip", limit: 10, period: 2.seconds) do |request|
    request.ip unless request.path.start_with?('/assets')
  end

  blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 30.minutes) do
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login')
    end
  end
end