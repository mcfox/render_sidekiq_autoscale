require './app/render_auto_scale'
require './app/sidekiq_counter'

begin
  puts "Starting auto scale service..."
  service_name = ENV['AUTOSCALE_SERVICE_NAME'] || 'app_worker'
  redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
  api_token = ENV['SIDEKIQ_RENDER_AUTOSCALE_API_TOKEN']
  if ENV['ENV'] == 'DEV'
    time_br = Time.now..getlocal('-03:00')
    if time_br.hour < 8 || time_br.hour > 20
      app.suspend_workers
      app.suspend_web
    end
  else
    app = RenderAutoScale.new(service_name, redis_url, api_token)
    puts "service_name: #{service_name}"
    puts "redis_url: #{redis_url}"
    app.adjust_workers
  end
  puts "Done."
end
