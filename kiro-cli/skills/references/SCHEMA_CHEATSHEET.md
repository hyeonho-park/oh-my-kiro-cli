# Schema Cheatsheet - Top 20 리소스 타입 필드 경로

---

## 공통 최상위 필드

모든 리소스에서 사용 가능:

| 필드 | 설명 |
|------|------|
| `.id` | 리소스 ID |
| `.type` | 리소스 타입 |
| `.meta.service` | CMDB 서비스 |
| `.meta.role` | CMDB 역할 |
| `.meta.zone` | 환경 |
| `.environment.k8sCluster` | K8S 클러스터 (K8S만) |
| `.environment.k8sNamespace` | K8S 네임스페이스 (K8S만) |
| `.environment.accountId` | AWS 계정 ID (AWS만) |
| `.environment.accountName` | AWS 계정 코드 (AWS만) |
| `.environment.region` | AWS 리전 (AWS만) |

---

## Kubernetes 리소스

### 1. K8S::Pod

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | Pod 이름 | N |
| `.configuration.metadata.namespace` | 네임스페이스 | N |
| `.configuration.status.phase` | 상태 (Running/Pending/Failed/Succeeded) | N |
| `.configuration.status.containerStatuses[0].ready` | Ready 여부 | Y |
| `.configuration.status.containerStatuses[0].restartCount` | 재시작 횟수 | Y |
| `.configuration.spec.containers[0].image` | 이미지 | N |
| `.configuration.spec.containers[0].resources.requests.cpu` | CPU 요청 | Y |
| `.configuration.spec.containers[0].resources.requests.memory` | 메모리 요청 | Y |
| `.configuration.metadata.labels` | 레이블 전체 | Y |

### 2. K8S::Deployment

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.metadata.namespace` | 네임스페이스 | N |
| `.configuration.spec.replicas` | 원하는 레플리카 수 | N |
| `.configuration.status.readyReplicas` | Ready 레플리카 수 | Y |
| `.configuration.status.availableReplicas` | Available 레플리카 수 | Y |
| `.configuration.status.updatedReplicas` | Updated 레플리카 수 | Y |
| `.configuration.spec.template.spec.containers[0].image` | 이미지 | N |

### 3. K8S::Service

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.metadata.namespace` | 네임스페이스 | N |
| `.configuration.spec.type` | 타입 (ClusterIP/NodePort/LoadBalancer) | N |
| `.configuration.spec.clusterIP` | Cluster IP | Y |
| `.configuration.spec.ports[0].port` | 포트 | Y |
| `.configuration.spec.ports[0].targetPort` | 타겟 포트 | Y |

### 4. K8S::Ingress

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.metadata.namespace` | 네임스페이스 | N |
| `.configuration.spec.rules[0].host` | 호스트 | Y |
| `.configuration.spec.rules[0].http.paths[0].path` | 경로 | Y |

### 5. K8S::ConfigMap

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.metadata.namespace` | 네임스페이스 | N |
| `.configuration.data` | 데이터 (key-value) | Y |

### 6. K8S::StatefulSet

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.spec.replicas` | 레플리카 수 | N |
| `.configuration.status.readyReplicas` | Ready 수 | Y |
| `.configuration.spec.template.spec.containers[0].image` | 이미지 | N |

### 7. K8S::DaemonSet

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.status.desiredNumberScheduled` | 원하는 수 | N |
| `.configuration.status.numberReady` | Ready 수 | Y |

### 8. K8S::Job

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.status.succeeded` | 성공 수 | Y |
| `.configuration.status.failed` | 실패 수 | Y |
| `.configuration.status.startTime` | 시작 시간 | Y |
| `.configuration.status.completionTime` | 완료 시간 | Y |

### 9. K8S::CronJob

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.spec.schedule` | 스케줄 | N |
| `.configuration.status.lastScheduleTime` | 마지막 실행 | Y |

### 10. K8S::Namespace

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.metadata.name` | 이름 | N |
| `.configuration.status.phase` | 상태 (Active/Terminating) | N |

---

## AWS 리소스

### 11. AWS::EC2::Instance

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.instanceId` | 인스턴스 ID | N |
| `.configuration.instanceType` | 타입 | N |
| `.configuration.state.name` | 상태 (running/stopped/terminated) | N |
| `.configuration.state.code` | 상태 코드 (0/16/48/80) | N |
| `.configuration.privateIpAddress` | Private IP | Y |
| `.configuration.publicIpAddress` | Public IP | Y |
| `.configuration.vpcId` | VPC ID | Y |
| `.configuration.subnetId` | Subnet ID | Y |
| `.configuration.tags.Name` | Name 태그 | Y |
| `.configuration.launchTime` | 시작 시간 | N |

### 12. AWS::RDS::DBInstance

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.dBInstanceIdentifier` | 인스턴스 ID | N |
| `.configuration.engine` | 엔진 (mysql/postgres/aurora 등) | N |
| `.configuration.engineVersion` | 엔진 버전 | N |
| `.configuration.dBInstanceStatus` | 상태 | N |
| `.configuration.dBInstanceClass` | 클래스 | N |
| `.configuration.endpoint.address` | 엔드포인트 | Y |
| `.configuration.endpoint.port` | 포트 | Y |
| `.configuration.allocatedStorage` | 스토리지 GB | N |
| `.configuration.multiAZ` | Multi-AZ 여부 | N |

### 13. AWS::S3::Bucket

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.name` | 버킷 이름 | N |
| `.configuration.creationDate` | 생성일 | N |
| `.environment.region` | 리전 | N |

### 14. AWS::EC2::VPC

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.vpcId` | VPC ID | N |
| `.configuration.cidrBlock` | CIDR 블록 | N |
| `.configuration.state` | 상태 | N |
| `.configuration.isDefault` | 기본 VPC 여부 | N |
| `.configuration.tags.Name` | Name 태그 | Y |

### 15. AWS::EC2::Subnet

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.subnetId` | Subnet ID | N |
| `.configuration.vpcId` | VPC ID | N |
| `.configuration.cidrBlock` | CIDR 블록 | N |
| `.configuration.availabilityZone` | AZ | N |
| `.configuration.availableIpAddressCount` | 사용 가능 IP 수 | N |

### 16. AWS::EC2::SecurityGroup

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.groupId` | SG ID | N |
| `.configuration.groupName` | SG 이름 | N |
| `.configuration.vpcId` | VPC ID | N |
| `.configuration.description` | 설명 | Y |

**주의**: `.configuration.ipPermissions` 등 대용량 배열은 **절대 포함 금지**

### 17. AWS::ElasticLoadBalancingV2::LoadBalancer

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.loadBalancerArn` | ARN | N |
| `.configuration.loadBalancerName` | 이름 | N |
| `.configuration.type` | 타입 (application/network) | N |
| `.configuration.scheme` | 스키마 (internet-facing/internal) | N |
| `.configuration.dNSName` | DNS 이름 | N |
| `.configuration.vpcId` | VPC ID | N |
| `.configuration.state.code` | 상태 | N |

### 18. AWS::EC2::RouteTable

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.routeTableId` | Route Table ID | N |
| `.configuration.vpcId` | VPC ID | N |
| `.configuration.tags.Name` | Name 태그 | Y |

**주의**: `.configuration.routes` 대용량 배열은 **절대 포함 금지**

### 19. AWS::EC2::VPCPeeringConnection

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.vpcPeeringConnectionId` | Peering ID | N |
| `.configuration.requesterVpcInfo.vpcId` | 요청자 VPC | N |
| `.configuration.accepterVpcInfo.vpcId` | 수락자 VPC | N |
| `.configuration.status.code` | 상태 | N |

### 20. AWS::IAM::Role

| 필드 | 설명 | null |
|------|------|------|
| `.configuration.roleName` | 역할 이름 | N |
| `.configuration.roleId` | 역할 ID | N |
| `.configuration.arn` | ARN | N |
| `.configuration.createDate` | 생성일 | N |

---

## 필드 경로 찾기 팁

1. **스키마 API 우선**: `inspect_cmdb_resource_schema(resource_type)`로 샘플 데이터 확인
2. **공통 패턴**: K8S는 `.configuration.metadata.name`, AWS는 다양 (리소스별 확인)
3. **대소문자 주의**: AWS 필드는 camelCase (`instanceId`, `vpcId`)
4. **null 안전**: 항상 `(.field // default)` 패턴 사용
5. **배열 접근**: `[0]` 인덱스 명시 필수
