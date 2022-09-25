require './app/render_auto_scale'

begin
  puts "Creating worker configs"
  service_name = ENV['AUTOSCALE_SERVICE_NAME']
  redis_url = ENV['REDIS_URL']
  api_token = ENV['SIDEKIQ_RENDER_AUTOSCALE_API_TOKEN']
  app = RenderAutoScale.new(service_name, redis_url, api_token)
  puts "Adjusting #{app.worker_service_name}..."
  app.adjust_workers
  puts "Done."
rescue => e
  puts e.message
end
