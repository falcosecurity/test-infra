package utils

var (
	SupportedArchs = map[string]string{
		"x86_64":  "amd64",
		"aarch64": "arm64",
	}
)

func IsArchSupported(arch string) bool {
	_, ok := SupportedArchs[arch]
	return ok
}

func ToDebArch(arch string) string {
	return SupportedArchs[arch]
}
