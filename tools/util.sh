function terraform-install() {
  [[ -f /usr/local/bin/terraform ]] && echo "`/usr/local/bin/terraform version` already installed at /usr/local/bin/terraform" && return 0
  LATEST_URL=$(curl -sL https://releases.hashicorp.com/terraform/index.json |
    jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' |
    sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n |
    tail -n1)
  curl ${LATEST_URL} > terraform.zip
  unzip terraform.zip
  rm -rf terraform.zip
  install terraform /usr/local/bin/
  terraform --version
  echo "Installed: `terraform`"
}


function terraform-lint-install () {
  [[ -f /usr/local/bin/tflint ]] && echo "`/usr/local/bin/tflint -v` already installed at /usr/local/bin/terraform" && return 0
  # from https://circleci.com/developer/orbs/orb/devops-workflow/terraform
  pkg_arch=linux_amd64
  LATEST_URL=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | jq -r ".assets[] | select(.name | test(\"${pkg_arch}\")) | .browser_download_url")
  curl ${LATEST_URL} > tflint.zip
  unzip tflint.zip
  rm -rf tflint.zip
  install tflint /usr/local/bin/
  tflint --version
  echo "Installed: `tflint`"
}