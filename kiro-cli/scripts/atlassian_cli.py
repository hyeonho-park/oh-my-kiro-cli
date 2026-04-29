#!/usr/bin/env python3
"""Atlassian CLI — Jira & Confluence REST API wrapper for AI agents.

Environment variables:
  ATLASSIAN_EMAIL       Atlassian account email
  ATLASSIAN_API_TOKEN   Personal Access Token (https://id.atlassian.com/manage-profile/security/api-tokens)
  ATLASSIAN_BASE_URL    Site URL (default: https://woowahanbros.atlassian.net)

All output is JSON for easy parsing by AI agents.
"""

import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error
import urllib.parse

BASE_URL = os.environ.get("ATLASSIAN_BASE_URL", "https://woowahanbros.atlassian.net")
EMAIL = os.environ.get("ATLASSIAN_EMAIL", "")
TOKEN = os.environ.get("ATLASSIAN_API_TOKEN", "")


def auth_header():
    if not EMAIL or not TOKEN:
        print(json.dumps({"error": "ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN env vars required"}))
        sys.exit(1)
    return "Basic " + base64.b64encode(f"{EMAIL}:{TOKEN}".encode()).decode()


def request(method, path, data=None, params=None):
    url = f"{BASE_URL}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)
    headers = {
        "Authorization": auth_header(),
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        try:
            err = json.loads(err)
        except json.JSONDecodeError:
            pass
        print(json.dumps({"error": e.code, "detail": err}, ensure_ascii=False, indent=2))
        sys.exit(1)


def read_content(args, flag_name="description"):
    """Read long content from --{flag}-file or --{flag} argument."""
    file_attr = f"{flag_name}_file"
    if hasattr(args, file_attr) and getattr(args, file_attr):
        with open(getattr(args, file_attr)) as f:
            return f.read()
    return getattr(args, flag_name, "") or ""


# ── Jira ──────────────────────────────────────────────────────────────

def jira_create_issue(args):
    desc = read_content(args, "description")
    fields = {
        "project": {"key": args.project},
        "issuetype": {"name": args.type},
        "summary": args.summary,
    }
    if desc:
        fields["description"] = desc
    if args.parent:
        fields["parent"] = {"key": args.parent}
    if args.labels:
        fields["labels"] = args.labels
    if args.assignee:
        fields["assignee"] = {"accountId": args.assignee}

    result = request("POST", "/rest/api/2/issue", {"fields": fields})
    key = result.get("key", "")
    print(json.dumps({
        "key": key,
        "id": result.get("id", ""),
        "url": f"{BASE_URL}/browse/{key}",
    }, indent=2))


def jira_search(args):
    params = {"jql": args.jql, "maxResults": str(args.max_results)}
    if args.fields:
        params["fields"] = ",".join(args.fields)
    result = request("GET", "/rest/api/2/search", params=params)
    issues = []
    for i in result.get("issues", []):
        f = i.get("fields", {})
        issues.append({
            "key": i["key"],
            "summary": f.get("summary", ""),
            "status": (f.get("status") or {}).get("name", ""),
            "priority": (f.get("priority") or {}).get("name", ""),
            "assignee": (f.get("assignee") or {}).get("displayName", ""),
            "updated": f.get("updated", ""),
            "issuetype": (f.get("issuetype") or {}).get("name", ""),
            "url": f"{BASE_URL}/browse/{i['key']}",
        })
    print(json.dumps({"total": result.get("total", 0), "issues": issues}, ensure_ascii=False, indent=2))


# ── Confluence ────────────────────────────────────────────────────────

def confluence_get_spaces(args):
    params = {}
    if args.key:
        params["spaceKey"] = args.key
    result = request("GET", "/wiki/rest/api/space", params=params)
    spaces = []
    for s in result.get("results", []):
        spaces.append({"id": s["id"], "key": s["key"], "name": s["name"]})
    print(json.dumps(spaces, ensure_ascii=False, indent=2))


def confluence_list_pages(args):
    params = {"spaceKey": args.space_key, "type": "page", "limit": str(args.limit)}
    if args.title:
        params["title"] = args.title
    result = request("GET", "/wiki/rest/api/content", params=params)
    pages = []
    for p in result.get("results", []):
        pages.append({"id": p["id"], "title": p["title"], "url": f"{BASE_URL}/wiki{p['_links']['webui']}"})
    print(json.dumps(pages, ensure_ascii=False, indent=2))


def confluence_get_children(args):
    params = {"limit": str(args.limit)}
    result = request("GET", f"/wiki/rest/api/content/{args.page_id}/child/page", params=params)
    pages = []
    for p in result.get("results", []):
        pages.append({"id": p["id"], "title": p["title"], "url": f"{BASE_URL}/wiki{p['_links']['webui']}"})
    print(json.dumps(pages, ensure_ascii=False, indent=2))


def confluence_create_page(args):
    body_html = read_content(args, "body")
    data = {
        "type": "page",
        "title": args.title,
        "space": {"key": args.space_key},
        "body": {"storage": {"value": body_html, "representation": "storage"}},
    }
    if args.parent_id:
        data["ancestors"] = [{"id": args.parent_id}]

    result = request("POST", "/wiki/rest/api/content", data)
    page_id = result.get("id", "")
    print(json.dumps({
        "id": page_id,
        "title": result.get("title", ""),
        "url": f"{BASE_URL}/wiki{result.get('_links', {}).get('webui', '')}",
    }, ensure_ascii=False, indent=2))


def confluence_search(args):
    params = {"cql": args.cql, "limit": str(args.limit)}
    result = request("GET", "/wiki/rest/api/content/search", params=params)
    pages = []
    for p in result.get("results", []):
        pages.append({
            "id": p["id"],
            "title": p["title"],
            "type": p["type"],
            "url": f"{BASE_URL}/wiki{p.get('_links', {}).get('webui', '')}",
        })
    print(json.dumps({"total": result.get("totalSize", 0), "results": pages}, ensure_ascii=False, indent=2))


# ── CLI ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Atlassian CLI for AI agents")
    svc = parser.add_subparsers(dest="service")

    # ── jira ──
    jira = svc.add_parser("jira")
    jcmd = jira.add_subparsers(dest="command")

    c = jcmd.add_parser("create-issue")
    c.add_argument("--project", required=True, help="Project key (e.g. CIE)")
    c.add_argument("--type", default="Story", help="Issue type (default: Story)")
    c.add_argument("--summary", required=True, help="Issue title")
    c.add_argument("--description", default="", help="Description text")
    c.add_argument("--description-file", help="Read description from file")
    c.add_argument("--parent", help="Parent issue key (e.g. CIE-123)")
    c.add_argument("--labels", nargs="*", default=[], help="Labels")
    c.add_argument("--assignee", help="Assignee account ID")
    c.set_defaults(func=jira_create_issue)

    s = jcmd.add_parser("search")
    s.add_argument("--jql", required=True, help="JQL query")
    s.add_argument("--max-results", type=int, default=20)
    s.add_argument("--fields", nargs="*", help="Fields to return")
    s.set_defaults(func=jira_search)

    # ── confluence ──
    conf = svc.add_parser("confluence")
    ccmd = conf.add_subparsers(dest="command")

    gs = ccmd.add_parser("get-spaces")
    gs.add_argument("--key", help="Space key filter")
    gs.set_defaults(func=confluence_get_spaces)

    lp = ccmd.add_parser("list-pages")
    lp.add_argument("--space-key", required=True, help="Space key (e.g. CLOUDINFRA)")
    lp.add_argument("--title", help="Title filter")
    lp.add_argument("--limit", type=int, default=50)
    lp.set_defaults(func=confluence_list_pages)

    gc = ccmd.add_parser("get-children")
    gc.add_argument("--page-id", required=True, help="Parent page ID")
    gc.add_argument("--limit", type=int, default=30)
    gc.set_defaults(func=confluence_get_children)

    cp = ccmd.add_parser("create-page")
    cp.add_argument("--space-key", required=True, help="Space key")
    cp.add_argument("--parent-id", help="Parent page ID")
    cp.add_argument("--title", required=True, help="Page title")
    cp.add_argument("--body", default="", help="HTML body content")
    cp.add_argument("--body-file", help="Read body from file")
    cp.set_defaults(func=confluence_create_page)

    sc = ccmd.add_parser("search")
    sc.add_argument("--cql", required=True, help="CQL query")
    sc.add_argument("--limit", type=int, default=25)
    sc.set_defaults(func=confluence_search)

    args = parser.parse_args()
    if not hasattr(args, "func"):
        parser.print_help()
        sys.exit(1)
    args.func(args)


if __name__ == "__main__":
    main()
