

control plane 需要能够访问所有 data-plane 集群的 Kubernetes API Server（不限于通过代理、VPN 等各种方法）

data plane 要能够访问 control-plane 的 istiod 服务
data plane 之间要能够直接访问各方 ingress gateway（从而访问其中的应用服务）




* Virtual Service、Gateway 等 CRD 均存储在 control plane 集群中，所有 data plane 只做 work load runner 用途
* 如果要启用 Automatic Sidecar Injection，那么对于应用所在 namespace，在所有集群都需要显式启用
* 如果要将应用部署到某个集群，需要将应用显式部署到多个集群



问题：
* 如果某应用所在 namespace 在某些 data plane 集群中不存在，有没有关系？
* 多集群模式下，链路跟踪怎么处理？  都上报到统一的位置
* 多集群模式下，指标监控怎么处理？  都由统一的 prometheus 来采集
* 多集群模式下，CRD 如果需要创建、生效到指定命名空间，怎么处理？   在 control plane 中也创建这些命名空间，但是不部署 workload