# Render Sidekiq Autoscale
[github](https://github.com/mcfox/render_sidekiq_autoscale)

## Getting Started
Esse processo roda de 30 em 30 minutos para definir o numero de instancias de um determinado servicos
baseado no numero de jobs no Sidekiq.
O algoritimo é muito simples:

jobs_per_instance
max_instances

    Min([RoundUp(total_jobs/ jobs_per_instance),max_instances])


