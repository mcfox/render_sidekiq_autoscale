require './app/render_auto_scale'
require './app/sidekiq_counter'

begin
  redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
  api_token = ENV['SIDEKIQ_RENDER_AUTOSCALE_API_TOKEN']
  queues_name = ENV['SIDEKIQ_QUEUES'] || 'default calculo'
  puts "Starting auto scale service..."
  puts "redis_url: #{redis_url}"
  queues = queues_name.split(' ')
  queues.each do |queue|
    service_name = ENV['AUTOSCALE_SERVICE_NAME'] || 'app_worker'
    if queue != 'default'
      service_name = "#{service_name}_#{queue}"
    end
    puts "service_name: #{service_name}"
    app = RenderAutoScale.new(service_name, redis_url, api_token, queue)
    app.adjust_workers
  end
  puts "Done."
end
