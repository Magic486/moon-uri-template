# moon-uri-template 规约

- 状态：Draft 0.1
- 日期：2026-07-23
- 目标标准：[RFC 6570 — URI Template](https://www.rfc-editor.org/rfc/rfc6570)
- 项目工作名：`moon-uri-template`

## 1. 文档目的

本文规定 `moon-uri-template` 的功能边界、公开数据模型、解析与展开语义、错误行为、命令行接口、测试要求和兼容性要求。

本文使用以下规范性术语：

- **必须**：实现不可省略，否则不符合本规约。
- **应该**：原则上需要实现，只有存在明确理由时才可偏离。
- **可以**：可选能力，不影响核心兼容性。

## 2. 项目定位

`moon-uri-template` 是一个使用 MoonBit 实现的 RFC 6570 Level 4 URI Template 解析与展开库，并提供可执行 CLI。

项目面向：

- MoonBit HTTP 客户端与服务端框架；
- OpenAPI、SDK 和代码生成工具；
- 超媒体 API 与资源发现工具；
- 需要安全、确定性构造 URI 的应用；
- 需要在 JS、Wasm 和 Native 后端复用 URI 模板逻辑的项目。

核心操作为：

```text
URI Template + 有类型的变量集合 → URI Reference
```

## 3. 范围

### 3.1 核心范围

首个稳定版本必须实现：

1. RFC 6570 Level 1 至 Level 4 完整模板语法；
2. 模板解析、语法校验和结构化错误；
3. 字符串、列表、关联数组三类变量值；
4. `{var}`、`{+var}`、`{#var}`、`{.var}`、`{/var}`、`{;var}`、`{?var}`、`{&var}`；
5. Prefix Modifier，例如 `{var:3}`；
6. Explode Modifier，例如 `{list*}`；
7. Unicode 码点处理、UTF-8 转换和百分号编码；
8. 未定义值、空字符串、空列表和空关联数组的标准行为；
9. 确定性展开结果；
10. 模板校验、变量查看和展开 CLI；
11. RFC 示例与通用兼容性测试集；
12. JS、Wasm、Native 三后端检查与测试。

### 3.2 明确不在核心范围内

首个稳定版本不负责：

- 发起 HTTP 请求；
- DNS、网络连接或资源存在性判断；
- 完整实现 RFC 3986 URI 解析、解析基准或规范化；
- OpenAPI 文档解析；
- Web 服务端路由匹配；
- 从 URI 无歧义地反向恢复变量；
- 模板中加入条件、循环、函数等自定义语言特性；
- 自动猜测字符串应作为路径、查询参数还是 Fragment；
- 对变量业务含义进行校验。

反向匹配可以在未来作为独立实验包研究，但不得宣称属于 RFC 6570 兼容能力。

## 4. 兼容等级

实现必须完整支持 Level 4。解析器不得只接受已实现子集后静默忽略更高级语法。

| 等级 | 必须支持的能力 |
|---|---|
| Level 1 | 简单字符串展开 `{var}` |
| Level 2 | 保留字符展开 `{+var}`、Fragment 展开 `{#var}` |
| Level 3 | 多变量以及 `. / ; ? &` 操作符 |
| Level 4 | Prefix、Explode、列表和关联数组 |

公开 API 应能查询模板所需的最低兼容等级，便于调用方诊断和展示。

## 5. 数据模型

### 5.1 变量值

核心变量值必须区分以下类型：

```mbt
pub(all) enum UriValue {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
} derive(Debug, Eq)
```

设计要求：

- `Scalar` 表示单个字符串；
- `List` 表示保持顺序的字符串列表；
- `Assoc` 表示保持顺序的键值对；
- `Assoc` 不应在内部转换为无序集合；
- 未定义变量通过变量集合中不存在该名称来表达；
- 空字符串必须与未定义变量区分；
- 空列表、空关联数组必须与未定义变量区分。

首版不引入隐式数字、布尔值和空值转换。上层 JSON 适配器可以提供显式转换策略。

### 5.2 模板结构

解析后的模板至少应包含以下概念：

```text
Template
└── Part[]
    ├── Literal
    └── Expression
        ├── Operator
        └── VariableSpec[]
            ├── Name
            └── Modifier
                ├── None
                ├── Prefix(length)
                └── Explode
```

公开 API 不必须暴露完整内部 AST，但必须提供：

- 原始模板文本；
- 模板变量名称；
- 最低兼容等级；
- 模板能否成功解析。

### 5.3 操作符属性

展开器应该使用统一的操作符属性表，而不是维护八套互相独立的字符串拼接实现。每个操作符至少具有：

- 首次展开前缀；
- 多值分隔符；
- 是否使用 `name=value` 形式；
- 空值的连接形式；
- 是否允许 URI 保留字符。

## 6. 模板语法

### 6.1 文本与表达式

模板由零个或多个普通文本片段和表达式组成。表达式使用匹配的 `{` 与 `}` 包围。

```text
/repos/{owner}/{repo}/issues{?page,labels*}
```

解析器必须：

- 识别普通文本和表达式边界；
- 拒绝未闭合或非法嵌套的大括号；
- 拒绝空表达式；
- 拒绝空变量名；
- 保留足够的源位置信息用于错误报告；
- 对 RFC 保留但尚未定义的操作符报告“不支持的保留操作符”，不得自行赋予语义。

### 6.2 变量名称

变量名称大小写敏感。解析器必须按 RFC 6570 的 `varname` 规则校验名称。

变量名称中的合法百分号编码必须验证其形式。非法 `%` 序列必须产生语法错误。

### 6.3 修饰符

Prefix Modifier：

```text
{var:3}
```

要求：

- 只允许用于标量字符串；
- 长度必须符合 RFC 6570 的数字范围与位数要求；
- 长度按 Unicode 字符计算，不按 UTF-8 字节或 UTF-16 code unit 计算；
- 不得截断一个 Unicode 码点；
- 与 Explode 不得同时使用。

Explode Modifier：

```text
{list*}
{keys*}
```

要求：

- 对列表和关联数组按操作符规则展开；
- 标量使用 `*` 时遵守 RFC 定义的标量行为；
- 保留输入列表和关联数组顺序。

## 7. 展开语义

### 7.1 基本操作符

| 表达式 | 用途 | 示例 |
|---|---|---|
| `{var}` | 简单展开 | `value` |
| `{+var}` | 允许保留字符 | `/foo/bar` |
| `{#var}` | Fragment | `#value` |
| `{.var}` | 点号标签 | `.value` |
| `{/var}` | 路径段 | `/value` |
| `{;var}` | 路径参数 | `;var=value` |
| `{?var}` | 查询参数开始 | `?var=value` |
| `{&var}` | 查询参数续接 | `&var=value` |

### 7.2 未定义值

变量不存在时必须跳过该变量。

如果表达式内所有变量均未定义，则：

- 不输出操作符前缀；
- 不输出分隔符；
- 不输出变量名；
- 不输出占位空串。

例如：

```text
模板：/issues{?state,page}
变量：{}
结果：/issues
```

### 7.3 空值

空字符串是已定义值，其结果取决于操作符：

```text
{?x} + x="" → ?x=
{;x} + x="" → ;x
```

实现必须通过测试明确覆盖空字符串、空列表、空关联数组和未定义值，禁止将其统一视为 falsy 值。

### 7.4 列表

列表展开必须区分普通和 Explode 形式：

```text
labels = ["bug", "help wanted"]

{?labels}  → ?labels=bug,help%20wanted
{?labels*} → ?labels=bug&labels=help%20wanted
{/labels*} → /bug/help%20wanted
```

### 7.5 关联数组

关联数组必须按输入顺序展开：

```text
filters = [("state", "open"), ("author", "alice")]

{?filters}  → ?filters=state,open,author,alice
{?filters*} → ?state=open&author=alice
```

### 7.6 百分号编码

实现必须区分：

- URI 非保留字符；
- URI 保留字符；
- 非 ASCII Unicode 字符；
- 合法和非法百分号序列；
- 普通展开与保留字符展开。

非 ASCII 字符必须先转换为 UTF-8，再逐字节生成大写 `%HH`。

普通展开只允许非保留字符保持原样。`+` 和 `#` 操作符按 RFC 规则允许保留字符保持原样。

项目必须对以下输入建立测试：

- ASCII；
- 空格；
- 中文；
- Emoji；
- 组合字符；
- `/`、`?`、`#`、`&`、`=`；
- 合法 `%HH`；
- 孤立 `%` 和非法十六进制序列。

### 7.7 Unicode

实现必须按 Unicode 码点处理 Prefix 长度，并按 UTF-8 进行 URI 百分号编码。

实现不应在核心展开过程中擅自改变变量值的 Unicode 规范化形式。可以提供显式 NFC 规范化适配器，但默认行为必须被文档化并保持跨后端一致。

## 8. 公开 API 草案

以下 API 是首版设计目标，实际名称应在编码前使用 `moon ide doc` 检查现有命名习惯：

```mbt
pub struct UriTemplate

pub(all) enum UriValue {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
}

pub fn UriTemplate::parse(
  source : StringView,
) -> UriTemplate raise UriTemplateError

pub fn UriTemplate::expand(
  self : UriTemplate,
  variables : Map[String, UriValue],
) -> String raise UriTemplateError

pub fn UriTemplate::variables(
  self : UriTemplate,
) -> Array[String]

pub fn UriTemplate::level(
  self : UriTemplate,
) -> Int

pub fn UriTemplate::source(
  self : UriTemplate,
) -> String

pub fn is_valid(
  source : StringView,
) -> Bool
```

API 设计约束：

- 公共具体类型必须定义在根包或非 `internal` 公共包；
- 内部解析器、编码器和展开辅助类型不得泄漏到公开签名；
- 解析后的模板应该可重复展开，避免每次重新解析；
- 展开过程不得修改模板；
- 同一模板和同一有序变量输入必须产生同一结果。

## 9. 错误模型

错误必须结构化，至少区分：

- 未闭合表达式；
- 非法文字字符；
- 空表达式；
- 非法操作符；
- 非法变量名称；
- 非法 Prefix；
- 冲突修饰符；
- 不适用的值类型；
- 非法百分号编码；
- 超出实现资源限制。

每个语法错误应该包含：

- 错误类别；
- 从零开始或从一开始的位置约定；
- 原始模板中的偏移；
- 简洁的人类可读消息；
- 可选的表达式文本。

CLI 应将错误输出到标准错误，并以非零状态码退出。

## 10. 资源限制与安全

库不得把 URI Template 当作输入校验或权限控制机制。

必须记录以下安全事实：

- `{+var}` 和 `{#var}` 可能允许变量引入 URI 结构字符；
- 模板展开不保证目标 URI 安全、可信或存在；
- 调用方不得把未验证 URI 直接用于 SSRF 敏感请求；
- 变量中可能包含令牌、用户信息等敏感内容，错误消息默认不得回显完整变量集合。

实现应该提供合理的防滥用限制，例如：

- 最大模板长度；
- 最大表达式数量；
- 单表达式最大变量数量；
- Prefix 最大合法值；
- 最大输出长度。

默认限制必须足以处理正常 API 模板，并可在文档中查到。若允许配置限制，配置必须显式，不得依赖全局可变状态。

## 11. CLI 规约

可执行程序工作名为 `moon-uri-template`。

### 11.1 `validate`

```text
moon-uri-template validate TEMPLATE
```

成功时输出模板最低等级和变量数量；失败时输出带位置的错误。

### 11.2 `variables`

```text
moon-uri-template variables TEMPLATE
```

按首次出现顺序输出去重后的变量名。

### 11.3 `expand`

```text
moon-uri-template expand TEMPLATE --variables variables.json
```

必须支持从 JSON 文件读取变量。可以附加支持重复 `--var key=value` 参数，但 JSON 是列表和关联数组的标准输入方式。

JSON 映射建议：

- JSON string → `Scalar`
- JSON array of strings → `List`
- JSON object of strings → `Assoc`
- 其他 JSON 类型默认报错，不做隐式字符串化

### 11.4 `inspect`

```text
moon-uri-template inspect TEMPLATE
```

可以输出供开发者查看的模板结构、表达式、变量、修饰符和兼容等级。输出格式不属于稳定库 API。

## 12. 包与文件组织

实际结构：

```text
moon-uri-template/
├── moon.mod
├── moon.pkg
├── README.mbt.md
├── README.md
├── LICENSE
├── types.mbt              # 公开类型 (UriTemplate, UriValue, Operator, …)
├── error.mbt              # 公开错误类型
├── parser.mbt             # 解析与校验 API
├── expand.mbt             # 展开 API
├── operator.mbt           # 操作符定义
├── json_adapter.mbt       # JSON → UriValue 适配器
├── *_wbtest.mbt           # 白盒与兼容性测试（同包访问私有类型）
├── *_test.mbt             # 黑盒测试
├── internal/
│   ├── moon.pkg
│   └── encoding.mbt       # 字符分类、UTF-8、百分号编码
├── cmd/
│   └── uri-template/
├── examples/
├── testdata/
└── tools/
```

规则：

- 根包拥有公共 `UriTemplate`、`UriValue` 和错误类型；
- `internal/encoding` 只负责字符分类、UTF-8 与百分号编码；
- 解析器与展开逻辑保持在根包中，因为这些模块之间共享私有类型；
- 白盒测试（使用私有类型）留在根包中；黑盒测试按文件后缀 `_wbtest.mbt` 与 `_test.mbt` 区分；
- CLI 不得包含核心展开逻辑；
- 不创建巨型 `util.mbt` 或 `impl.mbt`。

## 13. 测试与符合性

### 13.1 必测内容

必须覆盖：

1. RFC 6570 正文的 Level 1–4 示例；
2. `uri-templates/uritemplate-test` 基础和扩展用例；
3. 所有操作符与三种变量类型的组合；
4. Prefix 和 Explode；
5. 未定义与各种空值；
6. Unicode、UTF-8 和百分号编码；
7. 非法模板及错误位置；
8. 确定性；
9. JS、Wasm、Native 后端一致性。

### 13.2 测试数据合规

引入外部测试数据时必须：

- 在 `THIRD_PARTY.md` 或等效文件注明来源；
- 记录上游仓库链接、版本或 commit；
- 保留上游许可证和版权要求；
- 不将上游测试成果表述为本项目原创。

### 13.3 CI

CI 至少执行：

```text
moon check
moon test
moon fmt --check
```

并分别验证计划支持的后端。发布前执行 `moon info`，审查并提交生成的公共接口摘要。

## 14. 文档要求

README 必须包含：

- 项目用途和非目标；
- 安装方法；
- 最小标量示例；
- 查询参数示例；
- 列表和关联数组示例；
- Prefix 与 Explode 示例；
- Unicode 与编码说明；
- 错误处理示例；
- CLI 示例；
- 兼容等级和测试状态；
- 安全边界；
- 许可证和第三方测试数据来源。

公共 API 必须具有文档注释，并优先使用可测试的 `README.mbt.md` 示例。

## 15. 版本与兼容性

- `0.x` 阶段允许调整 API，但变更必须记录在 `CHANGELOG.md`；
- `1.0.0` 表示公开 API、错误大类和 RFC 6570 Level 4 行为稳定；
- 修复不符合 RFC 的行为可以在小版本中进行，但必须记录行为变化；
- 自定义扩展不得改变标准模板的含义；
- 若增加非标准语法，必须默认关闭并使用独立命名空间或模式。

## 16. 验收定义

达到首个稳定交付需同时满足：

- RFC 6570 Level 4 核心能力全部实现；
- 标准兼容性测试全部通过，例外有公开说明；
- `moon check`、`moon test`、格式检查通过；
- JS、Wasm、Native 的承诺范围均通过 CI；
- README 示例可直接运行；
- CLI 至少实现 `validate`、`variables`、`expand`；
- 根目录具有 OSI 认可的许可证；
- 第三方测试数据来源与许可证完整；
- 已发布到 mooncakes.io；
- 仓库具有清晰、连续、有意义的开发记录。
