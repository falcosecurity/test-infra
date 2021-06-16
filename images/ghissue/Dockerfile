FROM golang:1.16.5-alpine

ENV GH_ORG=falcosecurity
ENV GH_REPO=test-infra
ENV GH_ISSUE_TAGS=
ENV GH_ISSUE_ASSIGNEE=

USER 1000

RUN mkdir /tmp/workspace
WORKDIR /tmp/workspace

RUN XDG_CACHE_HOME=.cache go get -u github.com/hcgatewood/ghissue

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["ghissue","create","--byline=false","issue.txt"]
