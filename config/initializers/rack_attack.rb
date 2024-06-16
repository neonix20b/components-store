class Rack::Attack
  blocklist_ip("65.108.2.0/16")
  blocklist_ip("23.22.35.0/16")
  blocklist_ip("3.224.220.0/16")

  throttle("requests by ip", limit: 10, period: 2.seconds) do |req|
    if !req.path.start_with?('/assets') and !req.path.start_with?('/rails') and !req.path.start_with?('/up')
      # Rails.logger.error("Rack::Attack Too many requests from IP: #{req.ip}")
      req.ip
    end
  end

  throttle('post requests', limit: 2, period: 4.seconds) do |req|
    if req.post?
      # Rails.logger.error("Rack::Attack Too many POSTS from IP: #{req.ip}")
      req.ip
    end
  end

  blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 1, findtime: 10.minutes, bantime: 60.minutes) do
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      req.path.include?('administrator') ||
      req.path.include?('cgi-bin') ||
      req.path.ends_with?('.php') ||
      req.path.ends_with?('.yml') ||
      req.path.ends_with?('.aspx') ||
      req.path.ends_with?(".xml")
    end
  end
end