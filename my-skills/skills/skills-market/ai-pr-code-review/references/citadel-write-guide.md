# 学城 CR 文档创建指南（Step 6）

## ⚠️ 表格格式强制规范

**禁止在 `--file` 写入的 Markdown 中使用 `:::table{...}` 宏格式！**

学城的 `:::table{borderColor=...}` JSON 宏只在浏览器编辑器中生效，通过 `--file` 写入时会原样输出为乱码 JSON 字符串。

✅ 正确：标准 Markdown 表格
```markdown
| 文件名 | 变更类型 | +行数 | -行数 |
|--------|---------|-------|-------|
| Foo.java | 修改 | 12 | 3 |
```

❌ 禁止：`:::table{borderColor=...}` JSON 宏格式（会输出为原始 JSON 字符串）

---

## 写入命令

⚠️ 必须用 `--file` 方式写入，**禁止用 `--content` 传多行字符串**（`\n` 不会转换为真实换行，Markdown 会挤成一行）。

```bash
# 1. 把 CR 文档内容写入临时文件
cat > /tmp/cr_review_{prId}.md << 'EOF'
{完整 Markdown 内容，直接多行写入}
EOF

# 2. 用 --file 创建文档（⚠️ 不需要传 --mis，认证从缓存自动读取）
oa-skills citadel createDocument \
  --title "PR #{prId} Code Review：{标题}" \
  --file /tmp/cr_review_{prId}.md \
  --parentId "${CITADEL_PARENT_ID}"

# 3. 清理临时文件
rm -f /tmp/cr_review_{prId}.md
```

默认 `CITADEL_PARENT_ID`：`2749896619`（学城 CR 文档目录）

## 失败处理

降级：CR 结果输出到对话 + 大象通知提交人，**不阻塞 Step 7**。

## CatPaw 对比章节

创建文档后，从 PR overview 提取 CatPaw 评论（含 `🤖 AI Code Review`），写入文档「与 CatPaw 对比」章节。无 CatPaw 评论则跳过该章节。

## 文档结构模板

见 [comment-templates.md](comment-templates.md) — `学城 CR 文档结构模板` 小节。
