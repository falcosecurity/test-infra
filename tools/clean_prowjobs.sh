
prowjobs=$(kubectl get prowjobs --sort-by=.metadata.creationTimestamp |  grep -i "pending" | awk -F ' ' '{print $1}')
for i in "$prowjobs"
do
  "kubectl delete prowjob $i"
done