package utils

var (
	supportedArchs = map[string]string{
		"x86_64":  "amd64",
		"aarch64": "arm64",
	}
)

func IsArchSupported(arch string) bool {
	_, ok := supportedArchs[arch]
	return ok
}

func ToDebArch(arch string) string {
	return supportedArchs[arch]
}

func FromDebArch(debArch string) string {
	for arch, debianArch := range supportedArchs {
		if debianArch == debArch {
			return arch
		}
	}
	return ""
}
