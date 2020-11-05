data "kubernetes_service" "deck" {
  metadata {
    name      = "deck"
    namespace = "default"
  }
}

#data "aws_lb" "deck" {
#  name = data.kubernetes_service.deck.load_balancer_ingress[0].hostname
#}

#data "aws_lb_listener" "deck" {
#  load_balancer_arn = data.aws_lb.deck.arn
#  port              = 9090
#}

resource "aws_acm_certificate" "deck" {
  domain_name       = "prow.falco.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

#resource "aws_lb_listener_certificate" "deck" {
#  #listener_arn    = data.aws_lb_listener.deck.arn
#  listener_arn    = ""
#  certificate_arn = aws_acm_certificate.deck.arn
#}
