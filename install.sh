#!/usr/bin/env bash
# myagentlab agent-skills 一键安装脚本
# 用法: ./install.sh [目标目录]
# 默认安装到 ~/.hermes/skills/，同名已存在的 skill 跳过不覆盖
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${1:-$HOME/.hermes/skills}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/skills"

if [ ! -d "$SRC_DIR" ]; then
    echo "❌ 找不到 skills/ 目录（$SRC_DIR）" >&2
    exit 1
fi

mkdir -p "$INSTALL_DIR"

installed=0
skipped=0
for category_dir in "$SRC_DIR"/*/; do
    category="$(basename "$category_dir")"
    for skill_dir in "$category_dir"*/; do
        [ -d "$skill_dir" ] || continue
        skill="$(basename "$skill_dir")"
        target="$INSTALL_DIR/$category/$skill"
        if [ -e "$target" ]; then
            echo "⏭️  $category/$skill (已存在，跳过)"
            skipped=$((skipped + 1))
            continue
        fi
        mkdir -p "$INSTALL_DIR/$category"
        cp -r "$skill_dir" "$target"
        echo "✅ $category/$skill"
        installed=$((installed + 1))
    done
done

echo ""
echo "安装完成: $installed 个新装, $skipped 个跳过"
echo "目标目录: $INSTALL_DIR"
