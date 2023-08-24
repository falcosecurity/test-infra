package autogenerate

const (
	urlArchTemplate = "https://raw.githubusercontent.com/falcosecurity/kernel-crawler/kernels/{{ .Architecture }}/list.json"
	urlLastDistro   = "https://raw.githubusercontent.com/falcosecurity/kernel-crawler/kernels/last_run_distro.txt"
	OutputPathFmt   = "output/%s/%s/%s_%s_%s_%s" // Eg: output/5.0.1+driver/x86_64/falco_centos_5.14.0-325.el9.x86_64_1.{ko,o}
)

var (
	// Please add new supported build-new-drivers structures here,
	// so that the utility starts building configs for them.
	// Fields must have the same name used in kernel-crawler json keys.
	supportedDistros = []string{
		"AlmaLinux",
		"AmazonLinux",
		"AmazonLinux2",
		"AmazonLinux2022",
		"AmazonLinux2023",
		"BottleRocket",
		"CentOS",
		"Debian",
		"Fedora",
		"Minikube",
		"Talos",
		"Ubuntu",
	}
)
