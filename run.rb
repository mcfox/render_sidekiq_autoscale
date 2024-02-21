require './app/render_auto_scale'

begin
  puts "Starting auto scale service..."
  service_name = ENV['AUTOSCALE_SERVICE_NAME']
  redis_url = ENV['REDIS_URL']
  api_token = ENV['SIDEKIQ_RENDER_AUTOSCALE_API_TOKEN']
  app = RenderAutoScale.new(service_name, redis_url, api_token)
  puts "service_name: #{service_name}"
  puts "redis_url: #{redis_url}"
  app.adjust_workers
  puts "Done."
end
