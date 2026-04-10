# Shell Safety

## Timeout Rules

모든 장시간 실행 가능한 shell 명령은 반드시 `timeout` 래퍼를 사용한다.

### 카테고리별 기본 timeout

| 카테고리 | timeout | 예시 |
|----------|---------|------|
| 빌드 | `timeout 120` | `timeout 120 npm run build` |
| 테스트 | `timeout 120` | `timeout 120 npm test` |
| 패키지 설치 | `timeout 180` | `timeout 180 npm install` |
| 네트워크 요청 | `timeout 30` | `timeout 30 curl https://...` |
| 일반 명령 | `timeout 30` | `timeout 30 find / -name '*.log'` |

### timeout 불필요한 명령

빠른 조회 명령은 래핑하지 않는다:
- `ls`, `cat`, `head`, `tail -n`, `wc`
- `grep`, `find` (프로젝트 디렉토리 내)
- `echo`, `pwd`, `which`, `type`
- `git status`, `git log`, `git diff`
- `jq`, `sed`, `awk` (파일 대상)

## 금지 명령

다음 명령은 무한 대기를 유발하므로 절대 실행하지 않는다:

- `tail -f` / `tail --follow` — 무한 스트림
- `watch` — 무한 반복
- `top`, `htop` — 인터랙티브 모니터
- `less`, `more`, `man` — 인터랙티브 페이저
- `vim`, `vi`, `nano`, `emacs` — 인터랙티브 에디터
- `python3`, `node`, `irb` (인자 없이) — REPL
- `cat` (인자 없이) — stdin 대기
- `ssh` (원격 명령 없이) — 인터랙티브 세션
- `docker attach`, `docker exec -it` — 인터랙티브 컨테이너
- `sleep 100+` — 과도한 대기
- `npm start`, `yarn dev`, `pnpm serve` (timeout 없이) — 개발 서버

## 안전한 대안

| 위험 명령 | 안전한 대안 |
|-----------|------------|
| `tail -f file` | `tail -n 50 file` |
| `watch cmd` | `cmd` (한 번 실행) |
| `top` | `top -l 1` (macOS) 또는 `ps aux` |
| `npm start` | `timeout 10 npm start &` 또는 별도 터미널 |
| `curl url` (느린 서버) | `timeout 30 curl url` |
| `find /` | `timeout 30 find / ...` 또는 프로젝트 내로 범위 제한 |

## 파이프 명령

파이프 체인에서는 느린 구간만 래핑한다:

```bash
# Good
timeout 30 curl https://api.example.com/data | jq '.items[]'

# Bad — 전체를 래핑하면 jq도 timeout에 걸림
timeout 30 bash -c 'curl https://api.example.com/data | jq .items[]'
```

## 개발 서버

서버를 시작해야 하는 경우:
1. 백그라운드로 실행: `timeout 10 npm start &`
2. health check로 확인: `timeout 10 curl -s http://localhost:3000/health`
3. 작업 완료 후 정리: `kill %1` 또는 `pkill -f 'npm start'`
