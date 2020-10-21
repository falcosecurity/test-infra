#!/bin/bash

set -e

if type op &> /dev/null; then
  echo "Onepassword CLI exists"
  op --version
else
  echo "Onepassword CLI does not exist"
    case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
        mkdir temp
        curl -s \
          https://cache.agilebits.com/dist/1P/op/pkg/v1.7.0/op_linux_386_v1.7.0.zip \
          -o temp/op.zip
        unzip temp/op.zip -d temp/
        gpg --receive-keys \
          --keyserver pool.sks-keyservers.net \
          3FEF9748469ADBE15DA7CA80AC2D62742012EA22
        gpg --verify \
          temp/op.sig \
          temp/op
        mv temp/op /usr/local/bin
        rm -rf temp/
        ;;
    darwin*)
        brew cask install 1password-cli
        ;;
    *)
        export OS_NAME=notset
        ;;
    esac
fi


op signin falcosecurity.1password.com Email Secret-Key

##WIP
#address pulling down existing needed items for CICI pipelines.
