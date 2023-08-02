package autogenerate

const (
	urlArchTemplate = "https://raw.githubusercontent.com/falcosecurity/kernel-crawler/kernels/{{ .Architecture }}/list.json"
	urlLastDistro   = "https://raw.githubusercontent.com/falcosecurity/kernel-crawler/kernels/last_run_distro.txt"
	outputPathFmt   = "output/%s/falco_%s_%s"
)
