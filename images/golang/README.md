# Buildpack Golang Docker Image

## Overview

This folder contains the Buildpack Golang image that is based on the Bootstrap image. Use it to build Golang components of differing versions.

The image consists of:

- golang 1.13
- dep 0.5.4
- awscli


## Installation

To build the Docker image, run this command:

```bash
docker build -t images/golang .
```
