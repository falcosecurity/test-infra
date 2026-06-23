output "deck_aws_acm_certificate_validation_options" {
  value = aws_acm_certificate.deck.domain_validation_options
}

output "deck_aws_acm_certificate_arn" {
  value = aws_acm_certificate.deck.arn
}