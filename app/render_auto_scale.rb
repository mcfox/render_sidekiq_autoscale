require 'sidekiq'
require 'sidekiq/web'
require 'render_api'

class RenderAutoScale

  def initialize(service_name=nil, redis_url=nil, render_api_token=nil)
    @service_name = service_name || ENV['AUTOSCALE_SERVICE_NAME']
    @redis_url = redis_url ENV['REDIS_URL']
    @render_api_token = render_api_token || ENV['SIDEKIQ_RENDER_AUTOSCALE_API_TOKEN']
    crate_render_client
    Sidekiq.configure_server do |config|
      config.redis = {:namespace => 'AppSidekiq', :url => @redis_url }
    end
    Sidekiq.configure_client do |config|
      config.redis = {:namespace => 'AppSidekiq', :url => @redis_url }
    end
  end

  def crate_render_client
    unless @render_api_token
      puts 'Render API Token not available'
      return
    end
    @render_client ||= RenderAPI.client(@render_api_token)
    unless @render_client
      puts 'Could not connect to the Render API'
      return
    end
  end

  def count_queued_jobs
    total_enqueued = Sidekiq::Stats.new.enqueued
    count = 0
    queues = Sidekiq::Queue.all
    queues.each do |queue|
      count += queue.size
    end
    puts "redis_url: #{@redis_url}"
    puts "count_queued_jobs: #{count}"
    puts "total_enqueued: #{total_enqueued}"
    # vou usar os dois metodos e pegar o maior valor
    [count, total_enqueued].max
  end

  def count_running_jobs
    count = 0
    workers = Sidekiq::Workers.new
    workers.each do |_process_id, _thread_id, work|
      count += 1
    end
    count
  end

  def count_jobs
    count_running_jobs + count_queued_jobs
  end

  def service_id
    @service_id ||= @render_client.services.list(filters: { name: @service_name }).first.to_h['id']
  end

  def workers_running?
    @render_client.services.find(service_id).first.to_h['suspended'] != 'suspended'
  end

  def workers_count
    @render_client.services.find(service_id).first.to_h['num_instances'].to_i
  end

  def suspend_workers
    if workers_running?
      @render_client.services.suspend(service_id)
      puts "Suspending #{@service_name}"
    end
  end

  def desired_workers(total_jobs)
    jobs_per_worker = 20
    max_workers = 3
    min_workers = 0
    count = total_jobs / jobs_per_worker
    count = min_workers if count < min_workers
    count = max_workers if count > max_workers
    count
  end

  def scale_workers(num_instances)
    unless workers_running?
      @render_client.services.resume(service_id)
      puts 'Restarting worker services'
    end
    res = @render_client.services.scale(service_id, num_instances: num_instances)
    puts "Changing the number of instances to #{num_instances}"
    puts res.inspect
  end

  def adjust_workers
    total_jobs = count_jobs
    puts "#{total_jobs} jobs in queues."
    if total_jobs.zero?
      suspend_workers
    else
      scale_workers(desired_workers(total_jobs))
    end
    puts "Finished adjusting workers to #{desired_workers(total_jobs)}"
  end

  def resume_workers
    return if workers_running?
    total_jobs = count_jobs
    # se pediu para ligar, liga no minimo um
    total_jobs = 1 if total_jobs.zero?
    scale_workers(desired_workers(total_jobs))
  end

  def worker_service_name
    @service_name
  end
end