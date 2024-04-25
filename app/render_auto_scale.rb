require 'sidekiq'
require 'sidekiq/web'
require 'render_api'

class RenderAutoScale

  def initialize(service_name, redis_url, render_api_token, queue_name = nil)
    @service_name = service_name
    @render_api_token = render_api_token
    @counter = SidekiqCounter.new(redis_url, queue_name)
    @queue_name = queue_name
    crate_render_client
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

  def count_jobs
    @counter.enqueued_jobs + @counte.running_jobs_count
  end

  def service_id
    @service_id ||= @render_client.services.list(filters: { name: @service_name }).first.to_h['id']
  end

  def web_service_id
    service_name = replace(@service_name,'worker','web')
    @web_service_id ||= @render_client.services.list(filters: { name: service_name }).first.to_h['id']
  end

  def suspend_web
    if @render_client
      @render_client.services.suspend(web_service_id)
      puts "Suspending #{web_service_id}"
    end
  end

  def workers_running?
    if @render_client
      @render_client.services.find(service_id).first.to_h['suspended'] != 'suspended'
    else
      false
    end
  end

  def workers_count
    @render_client.services.find(service_id).first.to_h['num_instances'].to_i
  end

  def suspend_workers
    if @render_client && workers_running?
      @render_client.services.suspend(service_id)
      puts "Suspending #{@service_name}"
    end
  end

  def desired_workers(total_jobs)
    jobs_per_worker = 20
    max_workers = ENV['SIDEKIQ_MAX_WORKERS']&.to_i || 1
    min_workers = 0
    count = (total_jobs.to_f / jobs_per_worker).ceil
    count = min_workers if count < min_workers
    count = max_workers if count > max_workers
    count
  end

  def scale_workers(num_instances)
    unless @render_client
      puts 'Render API not available'
      return
    end
    unless workers_running?
      @render_client.services.resume(service_id)
      puts 'Restarting worker services'
    end
    res = @render_client.services.scale(service_id, num_instances: num_instances)
    puts "Changing the number of instances on #{@service_name} to #{num_instances}"
    puts res.inspect
  end

  def adjust_workers
    total_jobs = count_jobs
    puts "#{total_jobs} jobs in queue #{@queue_name || 'default'}."
    num_workers = desired_workers(total_jobs)
    if total_jobs.zero?
      suspend_workers
    else
      scale_workers(num_workers)
    end
    puts "Finished adjusting workers in #{@service_name} to #{num_workers}"
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