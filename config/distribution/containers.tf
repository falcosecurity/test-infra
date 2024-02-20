data "http" "falcosidekick_readme" {
  url = "https://raw.githubusercontent.com/falcosecurity/falcosidekick/master/README.md"
}

resource "aws_ecrpublic_repository" "falcosidekick" {
  provider = aws.us

  repository_name = "falcosidekick"

  catalog_data {
    description       = "A simple daemon to help you with falco's outputs"
    about_text        = substr(data.http.falcosidekick_readme.body, 0, 10240)
    architectures     = ["x86-64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "http" "falcosidekick_ui_readme" {
  url = "https://raw.githubusercontent.com/falcosecurity/falcosidekick-ui/master/README.md"
}

resource "aws_ecrpublic_repository" "falcosidekick_ui" {
  provider = aws.us

  repository_name = "falcosidekick-ui"

  catalog_data {
    description       = "A simple WebUI with latest events from Falco"
    about_text        = substr(data.http.falcosidekick_ui_readme.body, 0, 10240)
    architectures     = ["x86-64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "http" "falco_readme" {
  url = "https://raw.githubusercontent.com/falcosecurity/falco/master/README.md"
}

resource "aws_ecrpublic_repository" "falco" {
  provider = aws.us

  repository_name = "falco"

  catalog_data {
    description       = "Container Native Runtime Security for Cloud Native Platforms"
    about_text        = substr(data.http.falco_readme.body, 0, 10240)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecrpublic_repository" "falco_driver_loader" {
  provider = aws.us

  repository_name = "falco-driver-loader"

  catalog_data {
    description       = "Container Native Runtime Security for Cloud Native Platforms"
    about_text        = substr(data.http.falco_readme.body, 0, 10240)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecrpublic_repository" "falco_no_driver" {
  provider = aws.us

  repository_name = "falco-no-driver"

  catalog_data {
    description       = "Container Native Runtime Security for Cloud Native Platforms"
    about_text        = substr(data.http.falco_readme.body, 0, 10240)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecrpublic_repository" "falco_distroless" {
  provider = aws.us

  repository_name = "falco-distroless"

  catalog_data {
    description       = "Container Native Runtime Security for Cloud Native Platforms"
    about_text        = substr(data.http.falco_readme.body, 0, 10240)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecrpublic_repository" "falco_driver_loader_legacy" {
  provider = aws.us

  repository_name = "falco-driver-loader-legacy"

  catalog_data {
    description       = "Container Native Runtime Security for Cloud Native Platforms"
    about_text        = substr(data.http.falco_readme.body, 0, 10240)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "http" "falcoctl_readme" {
  url = "https://raw.githubusercontent.com/falcosecurity/falcoctl/main/README.md"
}

resource "aws_ecrpublic_repository" "falcoctl" {
  provider = aws.us

  repository_name = "falcoctl"

  catalog_data {
    description       = "Administrative tooling for Falco"
    about_text        = substr(data.http.falcoctl_readme.body, 0, 10200)
    architectures     = ["x86-64", "ARM 64"]
    operating_systems = ["Linux"]
  }

  lifecycle {
    prevent_destroy = true
  }
}
