#!/bin/sh

set -eu

cat <<EOF > issue.txt
${GH_ORG}/${GH_REPO}
---
${GH_ISSUE_TITLE} | ${GH_ISSUE_TAGS} | ${GH_ISSUE_ASSIGNEE}
${GH_ISSUE_BODY}
EOF

exec $@
