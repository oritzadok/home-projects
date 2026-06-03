# ACM certificate to attach to ALB for TLS termination.
# For more enterprise-grade, use AWS Private CA
resource "aws_acm_certificate" "wiki_internal" {
  private_key       = file("files/wiki.key")
  certificate_body  = file("files/wiki.crt")
  certificate_chain = null # not needed for self-signed

  tags = {
    Name = "wiki-internal-cert"
  }
}


# Private Route53 zone for internal DNS.
# To make the app hostname resolvable only inside our VPC
resource "aws_route53_zone" "internal" {
  name = "internal.local"
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
  comment = "Private zone for internal apps"
}


data "kubernetes_ingress_v1" "wiki" {
  metadata {
    name      = "wiki"
    namespace = helm_release.wiki.namespace
  }
}


# Route53 record pointing to the ALB DNS name that gets created upon Ingress creation
resource "aws_route53_record" "wiki" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "wiki.internal.local"
  type    = "CNAME"
  ttl     = 60
  records = [data.kubernetes_ingress_v1.wiki.status.0.load_balancer.0.ingress.0.hostname]
}