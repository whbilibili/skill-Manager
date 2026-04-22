# AGENTS.md — 全局索引路由（前端版）

> 本文件是 AI Coding Agent 的导航地图。**每次启动新 Session 必须先读此文件。** 任何新增文档都必须在此注册。

---

## 项目信息

- **项目名称**：[PROJECT_NAME]
- **技术栈**：[React/Next.js/Vue + 状态库 + 数据请求库]
- **创建时间**：[YYYY-MM-DD]
- **当前迭代**：[迭代名称或版本号]

---

## 文件索引

| 文件路径 | 说明 | Agent 权限 |
|----------|------|------------|
| `docs/exec-plans/feature-list.json` | 任务清单（待办/进行中/已完成） | 读写 |
| `docs/exec-plans/progress.txt` | 交接棒文件（Current Focus / Key Decisions / Dead Ends / Next Steps） | 读写 |
| `docs/exec-plans/issues.json` | 缺陷工单池 | 读写 |
| `docs/PRD.md` | 产品需求文档 | 只读 |
| `ARCHITECTURE.md` | 前端架构约束全集 | 读写 |
| `docs/CHANGELOG/` | 历史决策归档（progress.txt 裁剪后移入） | 只读 |
| `docs/caveats.md` | 踩坑永久档案（Dead Ends 长期版） | 读写 |
| `src/mocks/handlers/` | MSW Mock Handler 目录 | 读写（联调完成后删除对应文件） |

---

## 启动工作流（新 Session 必读）

每次启动新 Session，**按此顺序执行**：

1. 读取本文件（AGENTS.md），获取项目全局信息
2. 读取 `docs/exec-plans/progress.txt` 的 **[Current Focus]** 和 **[Dead Ends]**，了解当前攻坚点和已知陷阱
3. 读取 `docs/exec-plans/feature-list.json`，筛选 `status = "in_progress"` 的 Task
4. 如果没有 in_progress 的 Task，取第一个 `status = "pending"` 的 Task 开始执行
5. 执行 `./init.sh` 验证环境（不启动服务）
6. 开始执行 Task，每完成一个 Task 立即更新 feature-list.json 状态和 progress.txt

> ⚠️ **绝不跳过第 2 步**：[Dead Ends] 记录了已知无效路径，跳过会导致重复踩坑。

---

## 验证命令清单

### 自动验证（CI 可直接执行，有通过/失败断言）

```bash
# TypeScript 类型检查
npm run typecheck

# 单元测试
npm run test

# 构建验证
npm run build

# Mock 孤儿检查
bash init.sh --mock-check-only

# 缺陷池状态一致性检查
python3 -c "import json; issues=json.load(open('docs/exec-plans/issues.json')); print(f'\u2705 issues.json: {len(issues.get(\"issues\", []))} 条工单')" 2>/dev/null || echo 'ℹ️  issues.json 不存在，跳过'
```

### 人工确认（需视觉验证，无法机器断言）

```bash
# 启动开发服务器后在浏览器确认
npm run dev
# → 访问 /xxx 页面，确认组件渲染正确、交互符合 PRD
# → 确认响应式布局在 375px / 768px / 1280px 下表现正常
# → 对照 contracts.design_contract 逐项确认视觉实现（间距/色彩/字体/圆角）
# → 如有 Figma 稿，截图对比 design_contract.reference_figma，关键元素像素偏差 < 4px
```

> 💡 在 feature-list.json 的 `verification` 字段中，`auto` 对应自动验证，`visual` 对应视觉验证，`manual` 对应功能人工确认。

---

## 完成定义（DoD Checklist）

每个 Task 被标记为 `completed` 之前，必须通过以下检查：

- [ ] `npm run typecheck` 无 error（零容忍）
- [ ] 相关单元测试通过，覆盖率 ≥ 80%
- [ ] 如果 Task 有对应的联调 Task，Mock 文件已清理（`mocks/handlers/xxx.ts` 已删除）
- [ ] 组件 Props 有 TypeScript 类型声明（无 `any`）
- [ ] 自定义 Hook 有对应单测
- [ ] **视觉验证通过**：对照 `contracts.design_contract` 确认间距/色彩/字体/响应式均符合规范
- [ ] **色彩未硬编码**：样式中使用 CSS 变量（`var(--color-*)`）而非直接写色值
- [ ] progress.txt 已更新（[Current Focus] 和 [Next Steps]）
- [ ] feature-list.json 中 Task status 已更新为 `completed`

---

## 会话结束 Checklist

每次结束 Session 之前，必须完成：

1. **更新 progress.txt**：[Current Focus] 写入当前停在哪，[Next Steps] 写清楚下个 Session 第一步做什么
2. **更新 feature-list.json**：刚完成的 Task 标记 `completed`，刚开始的 Task 标记 `in_progress`
3. **检查 Mock 残留**：已联调完成的接口，对应的 Mock handler 是否已删除
4. **检查 Dead Ends**：本次 Session 踩到的坑是否记录到 progress.txt [Dead Ends] 或 `docs/caveats.md`
5. **触发 session-handoff 技能**（如有安装）

---

## Dead Ends 快速索引

> 详细记录在 `progress.txt` [Dead Ends] 区块和 `docs/caveats.md`。以下是高频陷阱摘要：

- **MSW + Vite HMR**：需在 `vite.config.ts` 中配置 `server.middlewareMode`，否则 HMR 刷新后 Mock 失效
- **useEffect 依赖数组**：缺少依赖会导致闭包过期，多余依赖会导致无限请求。必须启用 `eslint-plugin-react-hooks`
- **Zustand selector 无限渲染**：selector 返回新对象必须配合 `shallow` 比较，否则每次渲染都触发重新订阅
- **MSW 未在 vitest 初始化**：测试中 API 不被拦截，需在 `vitest.setup.ts` 中 `beforeAll(server.listen)` + `afterEach(server.resetHandlers)` + `afterAll(server.close)`
- **React Query staleTime 未设置**：默认 `staleTime: 0` 导致每次聚焦窗口都重新 fetch，影响用户体验

---

## 架构约束（红线）

以下约束由架构师决策，Coding Agent 不得违反：

1. **状态分层**：服务端数据只通过 React Query/SWR 管理，不得直接放入 Zustand Store
2. **Mock 生命周期**：每个 MSW handler 必须在 feature-list.json 中有对应的 removal_condition，不得无限期保留
3. **组件职责**：Page 组件只做数据获取和布局编排，业务逻辑下沉到 Hook，UI 细节下沉到 Component
4. **类型安全**：禁止使用 `any`，API 响应类型从 `response_shape` 自动生成（可用 zod 或手写 interface）
