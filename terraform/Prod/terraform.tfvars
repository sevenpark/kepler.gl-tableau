allowed_account_ids = ["084888172679"]

vpc_name = "prod-applications"
app_subnet_name = "prod-applications-kepler-private-*"
app_public_subnet_name = "prod-applications-public-*"

kepler_lb_name = "prod-kepler-lb"
kepler_tg_name = "prod-kepler-tg"

kepler_env = "prod"
kepler_certificate_arn = "arn:aws:acm:us-east-1:084888172679:certificate/ddbb8ab9-b078-4443-850a-374d902c1996"
kepler_branch = "master"

cluster_name = "seven-park-prod"

load_balancer_sg = "sg-0d9c9ea4b46f1447c"
task_count = 1