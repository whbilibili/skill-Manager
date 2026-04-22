# 通用规范（文件 / 目录 / 包）

## 命名（文件与目录）

### 【强制】命名法选型

- **单一类文件**：文件名用帕斯卡命名法（PascalCase）。
- **UI 组件目录/文件**：目录名 PascalCase；目录下常见为 `index.tsx`/`index.scss`。
- **单一导出实体文件**（实例/类型/函数）：文件名与导出同名（如 `parseArgs.ts`、`stopWatch.ts`、`TabStatus.ts`）。
- **其他情况**：使用连字符命名法（kebab-case）。

### 【建议】目录命名简洁

如 `src`, `utils`, `components`, `helpers`, `views/pages`, `modules`, `__tests__`, `docs`, `typings` 等。

### 【建议】文件名不重复目录名

例如 `api/log.js` 优于 `api/api-log.js`。

---

## 文件

### 【强制】UTF-8 无 BOM

### 【建议】文件末尾保留一个空行

---

## 目录

### 【强制】同目录禁止同名 `.js/.ts` 与 `.jsx/.tsx` 并存

导入不加后缀会冲突。

### 【强制】禁止目录与 js/jsx/ts/tsx 文件同名

导入歧义与构建兼容问题。

---

## 包

### 【强制】NPM 包源码必须使用 ESM（`import` / `export`）

### 【建议】对外发布包建议用 ESM 发布

利于 tree-shaking。
