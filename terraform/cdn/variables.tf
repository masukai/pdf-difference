# locals {
#   docs_domain_name        = "docs.idpos-syanai.glico.com"
#   aws_acm_certificate_arn = "arn:aws:acm:us-east-1:905418380338:certificate/2a167fbd-b551-4a61-b705-ff744091e2c0"
# } # ハードコード

variable "name" {
  type = string
}

variable "allow_cidr_blocks" {
  type = list(string)
}
