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
