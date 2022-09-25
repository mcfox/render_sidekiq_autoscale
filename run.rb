require './app/render_auto_scale'

begin
  puts "Creating worker configs"
  api_token = 'rnd_M57RvdKsIGwYoGBf8FpmnzVA0ku2'
  apps = []
  apps << RenderAutoScale.new('worker','redis://red-cbbvt9cgqg4cu6m01b70:6379', api_token)
  apps << RenderAutoScale.new('fact-worker','redis://red-cbtbsd319n0c5dqruk40:6379', api_token)
  puts "Running services"
  apps.each do |app|
    puts "Adjusting #{app.worker_service_name}..."
    app.adjust_workers
  end
  puts "Done."
rescue => e
  puts e.message
end
