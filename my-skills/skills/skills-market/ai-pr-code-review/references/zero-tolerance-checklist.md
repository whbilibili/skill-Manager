# 零容忍异常检查清单

以下异常类型命中零容忍红线，每引入一个都会影响 WBR 稳定性指标。

## 代码 BUG 类

- `NullPointerException` — 每个外部调用返回值、方法参数、集合元素做 null check；Map.get 拆箱风险
- `ClassCastException` — 强制类型转换前 instanceof 检查
- `IndexOutOfBoundsException` — list.get(i) 前检查 size；substring 参数边界
- `ConcurrentModificationException` — for-each 循环中不修改集合，用 Iterator.remove() 或 CopyOnWriteArrayList
- `NumberFormatException` — Integer.parseInt / Long.parseLong 有 try-catch
- `StackOverflowError` — 递归有终止条件 + 深度限制
- `OutOfMemoryError` — 无限增长集合、循环内大对象创建、大字符串拼接
- `NoSuchElementException` — Iterator.next() 前 hasNext()；Optional.get() 前 isPresent()
- `ArithmeticException` — 除法操作的除数非零检查
- `UnsupportedOperationException` — Collections.unmodifiableList 返回的集合不做修改操作
- `NoClassDefFoundError` / `ClassNotFoundException` — 依赖是否完整
- `NoSuchMethodError` — 依赖版本冲突

## KV 数据超限类

- `StoreBigValueException` — Squirrel 单 value 序列化后 < 10KB；批量查询 key 数量有上限；大对象拆分存储

## SQL 执行失败类

- `MySQLIntegrityConstraintViolationException` / `DuplicateKeyException` — INSERT 处理唯一键冲突（ON DUPLICATE KEY UPDATE 或 catch + 业务处理）
- `PacketTooBigException` — 批量 SQL 大小控制
- `MysqlDataTruncation` — 字段值长度校验
- `PoolExhaustedException` — 连接正确释放 + 慢 SQL 治理
- `MyBatisSystemException` — MyBatis 映射配置正确性

## Spring 异常类

- `BeanCreationException` — Bean 依赖完整性
- `NoSuchBeanDefinitionException` — 包扫描路径正确性

## 常见 NPE 场景

```java
// ❌ 链式调用未判空
String name = userService.getUserById(id).getName();

// ✅ 判空处理
User user = userService.getUserById(id);
if (user == null) {
    log.warn("user not found, id={}", id);
    return Result.fail("用户不存在");
}

// ❌ Map.get 直接拆箱
int count = map.get(key); // key 不存在时 NPE

// ✅ getOrDefault
int count = map.getOrDefault(key, 0);

// ❌ 集合为 null 时遍历
for (Item item : list) { ... } // list 为 null 时 NPE

// ✅ 空安全
if (CollectionUtils.isNotEmpty(list)) {
    for (Item item : list) { ... }
}

// ❌ 集合直接调用 contains/get 等方法，未判 null
list.contains(value); // list 为 null 时 NPE

// ✅ 空安全
if (CollectionUtils.isNotEmpty(list) && list.contains(value)) { ... }
```

> ⚠️ **集合 NPE 上下文感知规则（避免误报）**：
> 判断 `collection.contains()` / `collection.get()` / `collection.size()` 等调用是否有 NPE 风险时，**必须向上追溯同一个集合引用是否已经过 null-safe 保护**：
> - `CollectionUtils.isNotEmpty(collection)` — 已保护（false-on-null），不报 NPE
> - `CollectionUtils.isEmpty(collection)` — 已保护（true-on-null），不报 NPE
> - `collection != null` — 已保护，不报 NPE
> - `Objects.nonNull(collection)` — 已保护，不报 NPE
> - `Optional.ofNullable(collection).isPresent()` — 已保护，不报 NPE
>
> **误报场景示例**：
> ```java
> // 上游已有保护：
> if (CollectionUtils.isNotEmpty(j.getGrayCustomers())) {
>     // 此处 .contains() 是安全的，不应报 NPE
>     j.getGrayCustomers().contains(customerId);
> }
>
> // 或 Stream.filter 链中前置判断：
> .filter(j -> CollectionUtils.isNotEmpty(j.getGrayCustomers())
>           && j.getGrayCustomers().contains(Long.valueOf(customerId)))
> // ↑ isNotEmpty 已在同一布尔表达式前置短路，contains 安全，不报 NPE
> ```
>
> **注意**：追溯范围仅限**同一方法/lambda 作用域内的直接前置条件**，跨方法调用或不同路径下的保护不计入。
```

## 下线/删除类变更专项（DEL-01）

> **触发条件**：PR 中存在以下任意模式时，**必须执行本节检查，不可跳过**
> - 方法体内 `set*()`/`write*()` 调用被删除
> - 类字段被删除（尤其是 Future/Container/DTO 字段）
> - 接口实现类、公共方法被删除
> - 监控打点（Cat.logEvent/logError/logMetric）被删除
> - MdpConfig/Feature 开关分支被整体移除

### DEL-01 被删内容消费方存活检查

**必须执行**：用 `code-repo-search` 逐一搜索所有被删内容的消费方

```bash
SEARCH="python3 ~/.openclaw/skills/code-repo-search/repo_search.py"

# 搜索被删 setter 对应的 getter 引用
$SEARCH -r {org}/{repo} -k "getProductAddingItemFutures" --ext .java --json

# 搜索被删类字段名
$SEARCH -r {org}/{repo} -k "productSkuFutures" --ext .java --json
```

| 搜索结果 | 结论 | 级别 |
|---------|------|------|
| 无命中 | ✅ 已验证无残留消费方 | — |
| 有命中，命中处有 null 判断 | ✅ 已验证消费方有兜底 | — |
| 有命中，无 null 判断 | 🟠 残留消费方未同步删除，存在 NPE | **P1** |
| 监控删除但无替代监控 | 🟡 失去告警覆盖 | **P2** |

**禁止**：把"建议确认"甩给提交人，**能查的必须自己搜完再下结论**。

---

## 常见 Squirrel 大 Value 场景

```java
// ❌ 批量查询不限制 size
List<DealGroup> groups = queryService.queryByIds(allIds);

// ✅ 分批查询
Lists.partition(allIds, 200).forEach(batch -> {
    queryService.queryByIds(batch);
});
```
