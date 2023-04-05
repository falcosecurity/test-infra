package main

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"log"
	"math"
	"net/http"
	neturl "net/url"
	"os"
	"path/filepath"
	"strings"
)

const source = "https://falco-distribution.s3-eu-west-1.amazonaws.com/?list-type=2&prefix=driver"
const download = "https://download.falco.org/"

type ListBucketResult struct {
	XMLName               xml.Name  `xml:"ListBucketResult"`
	Contents              []Content `xml:"Contents"`
	NextContinuationToken string    `xml:"NextContinuationToken"`
	IsTruncated           string    `xml:"IsTruncated"`
}

type Content struct {
	Lib          string `json:"lib"`
	Arch         string `json:"arch"`
	Kind         string `json:"kind"`
	Kernel       string `json:"kernel"`
	Target       string `json:"target"`
	Key          string `xml:"Key" json:"name"`
	Download     string `json:"download"`
	SizeBytes    int    `xml:"Size" json:"sizebytes"`
	Size         string `xml:"SizeString" json:"size"`
	LastModified string `xml:"LastModified" json:"lastmodified"`
}

type List struct {
	Libs    []string `json:"lib"`
	Archs   []string `json:"arch"`
	Kinds   []string `json:"kind"`
	Targets []string `json:"target"`
}

type JSONFile struct {
	Index   List      `json:"index"`
	Drivers []Content `json:"drivers"`
}

var (
	destFolder string
	jsonFiles  map[string]JSONFile
)

func init() {
	jsonFiles = make(map[string]JSONFile)
	if len(os.Args) < 2 || os.Args[1] == "" {
		destFolder, _ = os.Getwd()
	}
	destFolder = strings.TrimSuffix(os.Args[1], "/")
	if err := os.MkdirAll(filepath.Dir(destFolder), 0754); err != nil {
		log.Fatal(err)
	}
}

func main() {
	fetchXML("")
	for i, j := range jsonFiles {
		f, err := json.Marshal(j)
		if err != nil {
			log.Fatal(err)
		}
		err = ioutil.WriteFile(i, f, 0755)
		if err != nil {
			log.Fatal(err)
		}
	}
	l := []string{}
	for _, i := range jsonFiles {
		l = removeDuplicateStr(append(l, i.Index.Libs...))
	}
	f, err := json.Marshal(l)
	if err != nil {
		log.Fatal(err)
	}
	err = ioutil.WriteFile(destFolder+"/index.json", f, 0755)
	if err != nil {
		log.Fatal(err)
	}
}

func fetchXML(token string) {
	url := source
	if token != "" {
		url += "&continuation-token=" + neturl.QueryEscape(token)
	}

	resp, err := http.Get(url)
	if err != nil {
		log.Fatalln(err)
	}
	defer resp.Body.Close()

	byteValue, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalln(err)
	}

	var listBucket ListBucketResult
	if err := xml.Unmarshal(byteValue, &listBucket); err != nil {
		log.Fatalln(err)
	}

	for _, i := range listBucket.Contents {
		k := i.Key
		if !strings.HasSuffix(k, ".ko") && !strings.HasSuffix(k, ".o") {
			continue
		}
		var key, lib, arch, kind, target, kernel string
		s := strings.Split(k, "/")
		lib = s[1]
		switch len(s) {
		case 3:
			arch = "x86_64"
			key = s[2]
		case 4:
			arch = s[2]
			key = s[3]
		default:
			continue
		}
		target = strings.Split(key, "_")[1]
		kernel = strings.TrimSuffix(strings.TrimSuffix(strings.Split(key, "_")[2], ".o"), ".ko")
		switch filepath.Ext(key) {
		case ".o":
			kind = "ebpf"
		case ".ko":
			kind = "kmod"
		default:
			kind = "unknown"
		}

		jf := jsonFiles[destFolder+"/"+lib+".json"]
		jf.Index.Libs = removeDuplicateStr(append(jf.Index.Libs, lib))
		jf.Index.Archs = removeDuplicateStr(append(jf.Index.Archs, arch))
		jf.Index.Kinds = removeDuplicateStr(append(jf.Index.Kinds, kind))
		jf.Index.Targets = removeDuplicateStr(append(jf.Index.Targets, target))

		jf.Drivers = append(jf.Drivers, Content{
			Lib:          lib,
			Arch:         arch,
			Key:          key,
			Kernel:       kernel,
			Target:       target,
			SizeBytes:    i.SizeBytes,
			Size:         humaneteBytes(uint64(i.SizeBytes)),
			LastModified: i.LastModified,
			Kind:         kind,
			Download:     download + neturl.QueryEscape(k),
		})
		jsonFiles[destFolder+"/"+lib+".json"] = jf
	}

	if listBucket.IsTruncated == "true" {
		fetchXML(listBucket.NextContinuationToken)
	}
}

func removeDuplicateStr(strSlice []string) []string {
	allKeys := make(map[string]bool)
	list := []string{}
	for _, item := range strSlice {
		if _, value := allKeys[item]; !value {
			allKeys[item] = true
			list = append(list, item)
		}
	}
	return list
}

func humaneteBytes(s uint64) string {
	sizes := []string{"B", "kB", "MB", "GB", "TB", "PB", "EB"}
	if s < 10 {
		return fmt.Sprintf("%d B", s)
	}
	e := math.Floor(math.Log(float64(s)) / math.Log(1024.0))
	suffix := sizes[int(e)]
	val := math.Floor(float64(s)/math.Pow(1024.0, e)*10+0.5) / 10
	f := "%.0f %s"
	if val < 10 {
		f = "%.1f %s"
	}

	return fmt.Sprintf(f, val, suffix)
}
