class SidekiqCounter
  def initialize
    require 'sidekiq'
    require 'sidekiq-status'

    redis_conn = proc {
      Redis.new(
        url: ENV["REDIS_URL"] || "redis://localhost:6379",
        driver: :hiredis,
        ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}
      )
    }

    Sidekiq.configure_client do |config|
      config.redis = ConnectionPool.new(size: 10, &redis_conn)
      Sidekiq::Status.configure_client_middleware config
    end

    Sidekiq.configure_server do |config|
      config.redis = ConnectionPool.new(size: 25, &redis_conn)
      Sidekiq::Status.configure_server_middleware config
    end

  end

  def total_jobs
    stats = Sidekiq::Stats.new
    stats.queues.values.sum
  end

end