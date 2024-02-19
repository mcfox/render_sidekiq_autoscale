# Render Sidekiq Autoscale

[github](https://github.com/mcfox/render_sidekiq_autoscale)

## Como usar

- Crie um branch para cada stack que voce quiser usar
- Altere o arquivo render.yaml para as configurações desse stack
- Crie um blueprint no render apontando par o branch que voce criou para esse stack
- Teste o cron job rodando manualmente para verificar se ele está apontando para o Worker e para o redis correto.

## Algoritimo de Autoscale

Esse processo roda de 30 em 30 minutos para definir o numero de instancias de um determinado servicos
baseado no numero de jobs no Sidekiq.
O algoritimo é muito simples:

    def desired_workers(total_jobs)
        jobs_per_worker = 20
        max_workers = 3
        min_workers = 0
        count = total_jobs / jobs_per_worker
        count = min_workers if count < min_workers
        count = max_workers if count > max_workers
        count
    end
