# Wiki + GitHub 트러블슈팅 지식 베이스

> 출처: Confluence Wiki 40건 + infra-kb-store 2024 케이스 130건 + GitHub 최신 이슈 (2026.04 기준)
> 용도: SSM/CW Logs/GitHub Analyzer 에이전트가 결과 분석 시 참조

## 1. VPC CNI / IP 할당

### 1-1. IP 할당 실패 → WARM 설정 점검

| 항목 | 내용 |
|------|------|
| 증상 | `failed to assign an IP address to container`, Pod ContainerCreating 고착 |
| 근본 원인 | `WARM_IP_TARGET`/`WARM_ENI_TARGET`/`MINIMUM_IP_TARGET` 미설정 또는 부적절 |
| 확인 | [kubectl] `kubectl -n kube-system get ds aws-node -o json \| jq '.spec.template.spec.containers[0].env'` |
| 확인 | [SSM] `GetVpcCniLogsDocument` → ipamd_recent에서 `warm IP stats` 검색 |
| 해결 | `WARM_IP_TARGET=1`, `MINIMUM_IP_TARGET` 상향 |
| GitHub | #1872 (WARM > MaxIPs/ENI 시 지연), #3351 (IP assign 실패) |
| Wiki | pageId=78359026, 78362190 |

### 1-2. vpc-cni 업그레이드 → SGP Probe 실패 (Critical)

| 항목 | 내용 |
|------|------|
| 증상 | SGP Pod CrashLoopBackOff, Readiness/Liveness Probe Failed |
| 근본 원인 | addon 업그레이드 시 `DISABLE_TCP_EARLY_DEMUX` conflict → default(false)로 리셋 |
| 확인 | [kubectl] `kubectl -n kube-system get ds aws-node -o json \| jq '.spec.template.spec.containers[0].env[] \| select(.name=="DISABLE_TCP_EARLY_DEMUX")'` |
| 해결 | addon config value API 사용, 또는 Helm 분리 배포 |
| GitHub | PR #1212 (tcp_early_demux 원인 분석) |
| Wiki | pageId=78371026 |

### 1-3. IP Cooldown Pod 생성 실패 (2025~2026 신규)

| 항목 | 내용 |
|------|------|
| 증상 | "ENI does not have available addresses" 에러, 서브넷 여유 있음에도 실패 |
| 근본 원인 | IP가 cooldown 상태에 갇힘 (v1.21.1-eksbuild.3), ipamd 초기화 타이밍 이슈 |
| 확인 | [SSM] `GetVpcCniLogsDocument` → ipamd_errors에서 `InsufficientCIDRBlock`, `cooldown` 검색 |
| 해결 | vpc-cni 버전 다운그레이드 또는 최신 패치 적용 |
| GitHub | #3584 (v1.21.1-eksbuild.3, EKS 1.33) |

### 1-4. SGP cool-down + DNS ARP 캐시

| 항목 | 내용 |
|------|------|
| 증상 | SGP Pod에서 DNS timeout, Branch ENI 재사용 시 패킷 누락 |
| 근본 원인 | Branch ENI cool-down(기본 60초) 중 ARP 캐시 불일치 |
| 확인 | [kubectl] `branchENICooldown` Helm 설정값 확인 (vpc-resource-controller 배포 values) |
| 확인 | [SSM] `GetVpcCniLogsDocument` → host_arp_cache에서 INCOMPLETE/STALE 엔트리 검색 |
| 확인 | [SSM] `GetEKSNodeLogsDocument` → dns_config에서 resolv.conf nameserver 확인 |
| 확인 | [수동] `ip netns exec <ns> dig @172.30.0.10` — SGP Pod 네임스페이스 진입 필요 |
| 해결 | cool-down 설정 조정, node-local-dns vs SGP 네임스페이스 격리 확인 |
| Wiki | pageId=78412288, 925736033 |

## 2. 노드 / kubelet / OOM

### 2-1. Prometheus OOM → 노드 NotReady 체인 (Critical)

| 항목 | 내용 |
|------|------|
| 증상 | 모니터링 노드 NotReady, Pod Terminating 유지 |
| 근본 원인 | thanos-sidecar limit 미설정 → Burstable QoS → 노드 메모리 고갈 → kubelet down |
| 확인 | [SSM] `GetEKSNodeLogsDocument` → dmesg_errors에서 `oom-kill`, `out of memory` |
| 확인 | [SSM] `GetEKSNodeLogsDocument` → oom_score_adj에서 kubelet(-999) vs sidecar(999) 비교 |
| 해결 | 모든 sidecar 컨테이너에 resource limits 필수 설정 |
| Wiki | pageId=78408468 |

### 2-2. Pod 기동/종료 지연 (PLEG)

| 항목 | 내용 |
|------|------|
| 증상 | 이미지 다운→시작 30초+, 종료 후 Terminating 2분+ |
| 근본 원인 | kubelet PLEG(GenericPLEG: 1초 Relist) 폴링 기반 → CRI API latency 전파 |
| 확인 | [SSM] `GetContainerdLogsDocument` → containerd_status, containerd_tasks |
| 확인 | [SSM] `GetContainerdLogsDocument` → containerd_version으로 버전 대조 |
| 해결 | containerd 버전 확인, EventedPLEG(1.27+) 검토 (단 버그 발견으로 주의) |
| Wiki | pageId=78373304 (코드분석), 78375818 |

### 2-3. containerd 포트 충돌 (2026 신규)

| 항목 | 내용 |
|------|------|
| 증상 | EFS CSI/Pod Identity Agent 등 addon CrashLoopBackOff, `bind: address already in use` |
| 근본 원인 | containerd CRI streaming server가 addon 포트(9809, 2703 등) 선점 |
| 확인 | [SSM] `GetContainerdLogsDocument` → addon_port_check에서 9809/2703 점유 프로세스 확인 |
| 확인 | [SSM] `GetEKSNodeLogsDocument` → node_info에서 `ip_local_reserved_ports` 값 확인 (NOT_SET → AMI 미패치) |
| 해결 | AMI v20260318+ 업그레이드 (ip_local_reserved_ports 설정됨) |
| GitHub | awslabs/amazon-eks-ami #2631 |

## 3. ALB / Webhook / Ingress

### 3-1. ALB Controller 9443 포트 SG 누락

| 항목 | 내용 |
|------|------|
| 증상 | Ingress 생성 시 status 미업데이트, webhook timeout |
| 확인 | [CW Logs] kube-apiserver-audit에서 webhook timeout 패턴 |
| 해결 | CP SG → NodeGroup SG 9443 포트 규칙 추가 |
| Wiki | pageId=78359042 |

### 3-2. ALB Controller v3 Webhook TLS 만료 (2026 신규, Critical)

| 항목 | 내용 |
|------|------|
| 증상 | `x509: certificate signed by unknown authority`, target group binding 업데이트 실패 |
| 근본 원인 | v3.0.0에서 Certificate resource 제거 → Secret 만료 → webhook TLS 실패 |
| 확인 | [CW Logs] kube-apiserver-audit에서 x509 에러, CloudTrail에서 업그레이드 시점 확인 |
| 해결 | `keepTLSSecret=false` Helm 설정, v3.0.0+ 최신 패치 |
| GitHub | #4541, #4572 |

### 3-3. ALB Controller v2→v3 마이그레이션

| 항목 | 내용 |
|------|------|
| 주의 | Helm chart 버전 정렬 변경 (v2.x=Helm v1.x → v3.x=Helm v3.x) |
| CRD | standard CRDs + LBC Gateway API CRDs + Gateway API CRDs(v1.3.0+) 재적용 필수 |
| 최신 | v3.2.0 (2026.04): Gateway API v1.5, ListenerSet, auto-detection |
| GitHub | v3.0.0 릴리스 노트 |

## 4. Network Policy (2025~2026 신규)

### 4-1. NP Agent map pointer 버그

| 항목 | 내용 |
|------|------|
| 증상 | aws-eks-nodeagent CrashLoopBackOff, 기존 Network Policy 깨짐 |
| 근본 원인 | v1.21.0 NP Agent v1.3.0의 map pointer overwrite 버그 |
| 해결 | v1.21.1로 업그레이드 필수 (NP Agent v1.3.1) |
| GitHub | aws-network-policy-agent #455 |

### 4-2. NP podSelector 불일치

| 항목 | 내용 |
|------|------|
| 증상 | 서비스 IP 접근 차단, Pod IP 직접 접근은 정상 |
| 근본 원인 | podSelector labels ≠ service selector → eBPF 매칭 실패 |
| 해결 | labels 통일 또는 NP selector 수정 |
| GitHub | #3602 (Open, 2026.02) |

### 4-3. Egress 차단 리그레션 (IPv6)

| 항목 | 내용 |
|------|------|
| 증상 | Ingress-only NP인데 Egress도 차단됨 |
| 근본 원인 | v1.20.x 리그레션, conntrack 방향 전환 이슈 |
| 해결 | vpc-cni 패치 적용 |
| GitHub | aws-network-policy-agent #456 |

## 5. EKS Addon 관리

### 5-1. CoreDNS tolerations 리셋

| 항목 | 내용 |
|------|------|
| 증상 | CoreDNS Pending (taint 통과 실패) |
| 근본 원인 | `eks:addon-manager`가 주기적으로 toleration 덮어씀 |
| 해결 | Managed Addon 대신 직접 YAML/Helm 배포 |
| Wiki | pageId=78359036 |

### 5-2. Helm release-name 충돌

| 항목 | 내용 |
|------|------|
| 증상 | `cannot re-use a name that is still in use` |
| 해결 | `sh.helm.release.v1.*` secret 삭제 후 재배포 |
| Wiki | pageId=78364460 |

## 6. IRSA / 인증

### 6-1. IRSA cross-account 실패

| 항목 | 내용 |
|------|------|
| 증상 | Jenkins slave에서 assume 실패 |
| 해결 | `web_identity_token_file` 설정 또는 직접 `sts assume-role` |
| Wiki | pageId=78359334 |

## 7. 최신 버전 참조 (2026.04 기준)

| 컴포넌트 | 최신 버전 | 핵심 변경 |
|----------|----------|----------|
| vpc-cni | v1.21.1 | Cluster Network Policy, NP Agent 버그 수정 |
| vpc-resource-controller | v1.7.2 | branchENICooldown 설정, cluster tag filter |
| alb-controller | v3.2.0 | Gateway API v1.5 GA, ListenerSet |
| eks-ami | v20260318 | containerd 2.2.1, addon port 예약, kernel 6.12 |
