#Useful Deubgging commands

#Get logs from microservices

kubectl logs -l app=hook --tail 100 > hook.log
kubectl logs -l app=deck --tail 100 > deck.log
kubectl logs -l app=crier --tail 100 > crier.log
kubectl logs -l app=prow-controller-manager --tail 100 > prow-controller-manager.log
kubectl logs -l app=ghproxy --tail 100 > ghproxy.log
kubectl logs -l app=horologium --tail 100 > horologium.log
kubectl logs -l app=sinker --tail 100 > sinker.log
kubectl logs -l app=statusreconciler --tail 100 > statusreconciler.log
kubectl logs -l app=tide --tail 100 > tide.log




kubectl get prowjobs --sort-by=.metadata.creationTimestamp --namespace default |  grep -i "pending" | awk -F ' ' '{print $1}' | xargs kubectl delete pod --force

kubectl get prowjobs --sort-by=.metadata.creationTimestamp |  grep -i "pending" | awk -F ' ' '{print $1}' | xargs kubectl delete pod --namespace test-pods --force  
