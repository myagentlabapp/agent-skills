#!/usr/bin/env python3
"""CSV → NocoDB 导入（裸数组 100/批；--key 指定主键列自动去重跳过已有行）

用法:
  python3 nocodb_import.py <csv路径> <tableId> --token <xc-token> \
      --base http://localhost:18080 [--key QQ号]

注意:
  - 批量插入必须用裸数组，不要用 {"records": [...]} 包装（那样每批只插 1 条）
  - 单批上限 100 条
  - --key 会先拉取表内已有主键集合，跳过重复（表默认无唯一约束）
  - 大文件建议 nohup 后台跑 + tail 日志轮询（ssh_exec 约 60s 超时）
"""
import argparse
import csv
import json
import urllib.error
import urllib.request


def call(base, token, method, path, body=None):
    req = urllib.request.Request(base + path, method=method)
    req.add_header("Content-Type", "application/json")
    req.add_header("xc-token", token)
    if body is not None:
        req.data = json.dumps(body).encode()
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def get_all(base, token, table):
    rows, offset = [], 0
    while True:
        st, resp = call(base, token, "GET",
                        f"/api/v2/tables/{table}/records?limit=1000&offset={offset}")
        batch = json.loads(resp).get("list", [])
        rows.extend(batch)
        if len(batch) < 1000:
            break
        offset += 1000
    return rows


def main():
    ap = argparse.ArgumentParser(description="CSV 导入 NocoDB")
    ap.add_argument("csv", help="CSV 文件路径（utf-8-sig）")
    ap.add_argument("table", help="NocoDB table ID")
    ap.add_argument("--token", required=True, help="NocoDB API token (xc-token)")
    ap.add_argument("--base", default="http://localhost:18080")
    ap.add_argument("--key", default="", help="主键列名，传了则跳过已存在的行（去重）")
    args = ap.parse_args()

    rows = [{k: v for k, v in r.items()}
            for r in csv.DictReader(open(args.csv, encoding="utf-8-sig"))]
    print(f"CSV {len(rows)} 条", flush=True)

    if args.key:
        existing = {r.get(args.key) for r in get_all(args.base, args.token, args.table)}
        rows = [r for r in rows if r.get(args.key) not in existing]
        print(f"去重后 {len(rows)} 条（表内已有 {len(existing)}）", flush=True)

    ok = 0
    for i in range(0, len(rows), 100):
        chunk = rows[i:i + 100]  # 裸数组！不要 {"records": [...]} 包装
        st, resp = call(args.base, args.token, "POST",
                        f"/api/v2/tables/{args.table}/records", chunk)
        if st == 200:
            try:
                ok += len(json.loads(resp))
            except Exception:
                ok += len(chunk)
        else:
            print(f"批次失败 {i}: {st} {resp[:150]}", flush=True)
        if (i // 100) % 10 == 0:
            print(f"进度 {i + len(chunk)}/{len(rows)} (成功 {ok})", flush=True)

    # 最终验证：查 totalRows
    st, resp = call(args.base, args.token, "GET",
                    f"/api/v2/tables/{args.table}/records?limit=1")
    try:
        print(f"表 totalRows: {json.loads(resp).get('pageInfo', {}).get('totalRows')}", flush=True)
    except Exception:
        pass
    print(f"== 完成: {ok}/{len(rows)} ==", flush=True)


if __name__ == "__main__":
    main()
