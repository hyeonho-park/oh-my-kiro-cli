# Shell Safety

## Timeout Rules

Any shell command that may run long MUST be wrapped with `timeout`.

### Default timeout by category

| Category | timeout | Example |
|----------|---------|---------|
| Build | `timeout 120` | `timeout 120 npm run build` |
| Test | `timeout 120` | `timeout 120 npm test` |
| Package install | `timeout 180` | `timeout 180 npm install` |
| Network request | `timeout 30` | `timeout 30 curl https://...` |
| General command | `timeout 30` | `timeout 30 find / -name '*.log'` |

### Commands that do not need a timeout

Fast read-only commands do not need wrapping:
- `ls`, `cat`, `head`, `tail -n`, `wc`
- `grep`, `find` (within the project directory)
- `echo`, `pwd`, `which`, `type`
- `git status`, `git log`, `git diff`
- `jq`, `sed`, `awk` (against a file)

## Forbidden commands

The following commands cause indefinite hangs and must NEVER be executed:

- `tail -f` / `tail --follow` — infinite stream
- `watch` — infinite loop
- `top`, `htop` — interactive monitors
- `less`, `more`, `man` — interactive pagers
- `vim`, `vi`, `nano`, `emacs` — interactive editors
- `python3`, `node`, `irb` (with no arguments) — REPL
- `cat` (with no arguments) — waits on stdin
- `ssh` (without a remote command) — interactive session
- `docker attach`, `docker exec -it` — interactive containers
- `sleep 100+` — excessive waits
- `npm start`, `yarn dev`, `pnpm serve` (without a timeout) — dev servers

## Safe alternatives

| Risky command | Safe alternative |
|---------------|------------------|
| `tail -f file` | `tail -n 50 file` |
| `watch cmd` | `cmd` (run once) |
| `top` | `top -l 1` (macOS) or `ps aux` |
| `npm start` | `timeout 10 npm start &` or a separate terminal |
| `curl url` (slow server) | `timeout 30 curl url` |
| `find /` | `timeout 30 find / ...` or scope to the project directory |

## Piped commands

In a pipe chain, only wrap the slow segment:

```bash
# Good
timeout 30 curl https://api.example.com/data | jq '.items[]'

# Bad — wrapping the whole pipe times out jq as well
timeout 30 bash -c 'curl https://api.example.com/data | jq .items[]'
```

## Dev servers

When a server must be started:
1. Run in the background: `timeout 10 npm start &`
2. Confirm via health check: `timeout 10 curl -s http://localhost:3000/health`
3. Clean up after the task: `kill %1` or `pkill -f 'npm start'`
