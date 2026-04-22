# Vue 规范

## 1) 基础原则

### 【强制】模板 attribute 必须带引号，且强制双引号

### 【强制】Vue 文件 JS 代码每行建议用分号结束

### 【强制】Prop 声明用 camelCase，模板/JSX 用 kebab-case

### 【建议】模板只写简单表达式；复杂逻辑抽到 computed/method

### 【建议】computed 拆分为多个更简单的属性

### 【建议】避免隐式父子通信（$parent）；优先 props + 事件

### 【建议】全局状态避免 $root/事件总线；优先 Vuex

### 【建议】样式作用域：scoped/CSS Modules

---

## 2) Template 规范

### 【强制】不要省略闭合标签

### 【强制】无子元素使用自闭合（组件标签）

### 【强制】循环模板禁止覆盖已声明变量

### 【强制】避免 v-if 与 v-for 同元素

### 【建议】禁止不符合 HTML 语法的模板（编译器无法正常编译）

### 【强制】template 标签必须带具体指令，禁止空 template

### 【建议】slot 传参多个值时传对象

### 【强制】模板中禁止使用 this

### 【强制】模板组件属性名使用 kebab-case

### 【强制】组件命名 PascalCase；模板中组件名 PascalCase

### 【建议】标签单行则同一行闭合，多行则换行闭合；闭合前不留空格

### 【建议】每行一个属性；多子标签分行编写（除 pre/textarea）

### 【强制】`{{ }}` 内首尾加空格：`{{ text }}`

### 【强制】标签内禁止多个连续空格；`=` 两侧不加空格

### 【强制】缩进 2 空格；引号双引号

### 【强制】HTML void 元素（img/br/hr 等）不使用自闭合写法；其他无内容用自闭合

### 【建议】标签与内容尽量分行

### 【强制】属性顺序固定：DEFINITION → LIST_RENDERING → CONDITIONALS → ... → EVENTS → CONTENT

### 【强制】SFC 顶层标签顺序为 `<script>`/`<template>`/`<style>` 或 `<template>`/`<script>`/`<style>`

---

## 3) Props

### 【强制】props 需定义类型（或校验器）与默认值（undefined 除外）

### 【强制】Boolean 类型 prop 可不写默认值

### 【强制】props 中属性名 camelCase

---

## 4) 指令与插槽

### 【强制】用 `:prop` 替代 `v-bind:prop`

### 【强制】用 `@event` 替代 `v-on:event`

### 【强制】插槽：组件上用 `v-slot`；template 默认插槽 `#default`，具名 `#named`

### 【强制】v-for 必须设置 key

### 【建议】v-if/v-else-if/v-else 建议设置 key

---

## 5) 组件声明

### 【强制】使用单文件组件；非 SFC 时一个文件只能声明一个组件

### 【强制】事件名 camelCase（emit 的 name）

### 【建议】组件选项书写顺序按约定（name/props/data/computed/watch/methods/...）
