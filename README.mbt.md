# moon-uri-template

基于 MoonBit 纯实现的
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) Level 4 URI Template 库。

`moon-uri-template` 将 URI 模板解析一次后，可反复使用类型化的标量、列表或关联数组
值进行展开。适用于 HTTP 客户端、OpenAPI 工具、SDK 生成器、超媒体 API 以及
跨后端 MoonBit 应用。

命名空间：`Magic486/moon-uri-template`。

- **mooncakes**: <https://mooncakes.io/packages/Magic486/moon-uri-template>
- **GitHub**: <https://github.com/Magic486/moon-uri-template>
- **GitLink**: <https://www.gitlink.org.cn/Magic486/moon-uri-template>

## 安装

```bash
moon add Magic486/moon-uri-template
```

同一模块中的应用可直接导入根包。

## 功能特性

- RFC 6570 Levels 1–4
- 全部标准操作符：简单展开、`+`、`#`、`.`、`/`、`;`、`?`、`&`
- Prefix 与 Explode 修饰符
- 有序的标量、列表和关联数组值
- Unicode 码点感知的 Prefix 截取
- UTF-8 百分号编码
- 带源位置信息的结构化错误
- 显式的解析器与展开输出资源限制
- Wasm、Wasm-GC、JavaScript、Native 四后端确定性展开
- JSON 变量适配器
- `validate`、`variables`、`inspect`、`expand` 四个 CLI 命令
- 153 个引入的标准互操作性测试用例及项目专属测试

## 库示例

最小标量展开——解析一次并传入类型化值：

```mbt check
///|
test "expand one scalar" {
  let template = UriTemplate::parse("hello/{name}")
  let variables : Map[String, UriValue] = { "name": Scalar("MoonBit") }
  assert_eq(template.expand(variables), "hello/MoonBit")
}
```

真实端点可组合路径、查询参数和列表展开：

```mbt check
///|
test "expand a repository issues URI" {
  let template = UriTemplate::parse(
    "/repos/{owner}/{repo}/issues{?page,labels*}",
  )
  let variables : Map[String, UriValue] = {
    "owner": Scalar("moonbitlang"),
    "repo": Scalar("core"),
    "page": Scalar("2"),
    "labels": List(["bug", "help wanted"]),
  }
  assert_eq(
    template.expand(variables),
    "/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted",
  )
}
```

## 值模型

```mbt nocheck
///|
pub(all) enum UriValue {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
}
```

列表和关联数组保留输入顺序。Map 中不存在的条目表示未定义变量。空字符串视为已定义；
空列表和空关联数组在 RFC 6570 展开中被视为未定义。

### Prefix 修饰符

```mbt check
///|
test "prefix length counts Unicode code points" {
  let template = UriTemplate::parse("{value:2}")
  let variables : Map[String, UriValue] = { "value": Scalar("月兔Moon") }
  assert_eq(template.expand(variables), "%E6%9C%88%E5%85%94")
}
```

### Explode 修饰符

```mbt check
///|
test "explode a list into repeated query parameters" {
  let template = UriTemplate::parse("{?labels*}")
  let variables : Map[String, UriValue] = {
    "labels": List(["bug", "help wanted"]),
  }
  assert_eq(template.expand(variables), "?labels=bug&labels=help%20wanted")
}
```

关联数组保留键值对顺序，并可展开为命名查询参数：

```mbt check
///|
test "expand an associative value" {
  let template = UriTemplate::parse("{?filters*}")
  let variables : Map[String, UriValue] = {
    "filters": Assoc([("state", "open"), ("author", "月兔")]),
  }
  assert_eq(template.expand(variables), "?state=open&author=%E6%9C%88%E5%85%94")
}
```

## 资源限制

`UriTemplate::parse` 接受最大 1 MiB 的模板，最多包含 4096 个表达式和每个表达式
256 个变量。接受不可信模板的服务和工具可使用更严格的每次调用上限：

```mbt check
///|
test "parse with application-specific limits" {
  let template = UriTemplate::parse_with_limits(
    "/users/{name}{?page}",
    max_template_length=128,
    max_expressions=2,
    max_variables_per_expression=4,
  )
  assert_true(template.variables() == ["name", "page"])
}
```

展开默认限制为 1 MiB。当应用需要不同的显式限制时，可使用 `expand_with_limit`。

## 错误处理

解析与展开返回结构化的 `UriTemplateError` 值。语法错误携带 UTF-16 源偏移量；
值错误和限制错误标识其类别，但不回显完整变量集合。

```mbt check
///|
test "handle a syntax error with its source offset" {
  let rejected = try UriTemplate::parse("{unclosed") catch {
    SyntaxError(offset~, message=_) => offset == 0
    _ => false
  } noraise {
    _ => false
  }
  assert_true(rejected)
}
```

## JSON 变量

`variables_from_json` 接受一个 JSON 对象：

- 字符串 → `Scalar`
- 字符串数组 → `List`
- 字符串值对象 → 有序 `Assoc`

数字、布尔值、null、嵌套数组和非字符串关联值将被拒绝，不做隐式字符串化。

```json
{
  "owner": "moonbitlang",
  "repo": "core",
  "page": "2",
  "labels": ["bug", "help wanted"]
}
```

## CLI

从本仓库运行：

```bash
moon run cmd/uri-template -- validate '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- variables '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- inspect '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- expand \
  '/repos/{owner}/{repo}/issues{?page,labels*}' \
  --variables examples/variables.json
```

展开命令输出：

```text
/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted
```

## 标准符合性

项目引入了 Apache-2.0 许可的
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
测试集（固定于 commit `4171dac22aa67fc710b3f6df308a50bd08552986`）。

测试生成器生成 153 个 MoonBit 测试，覆盖：

- RFC 规范示例
- 扩展的互操作用例
- 非法模板和负向测试
- 多字节字符的 Prefix 处理
- 保留字符和百分号编码值
- 文字编码

运行：

```bash
powershell -NoProfile -ExecutionPolicy Bypass \
  -File tools/generate_conformance_tests.ps1
moon test --target all
```

所有生成及本地测试当前在 Wasm、Wasm-GC、JavaScript 和 Native 后端均通过，
使用的 MoonBit 工具链为 2026-07-03 版本。

## 安全边界

URI Template 展开不是输入校验或授权。

- `{+var}` 和 `{#var}` 刻意允许 URI 保留字符；
- 不可在对不可信展开值发起 SSRF 敏感网络请求前，先应用独立的 scheme、host、port 和
  目标策略；
- 错误信息不包含完整变量集合；
- `expand` 强制施加 1 MiB 的默认输出限制；
- `expand_with_limit` 允许应用设置更严格的限制；
- `parse_with_limits` 在模板不可信时可限制模板长度、表达式数量和每个表达式的变量数。

本库不发送 HTTP 请求、不解析相对引用、不检查资源是否存在，也不从 URI 反向匹配变量。

## 开发

```bash
moon check --warn-list +73
moon test --target all
moon fmt --check
moon info
```

项目范围和验收要求在 [SPEC.md](docs/SPEC.md) 中定义。交付优先级和里程碑在
[GOALS.md](docs/GOALS.md) 中跟踪。第三方声明记录在 [THIRD_PARTY.md](docs/THIRD_PARTY.md)。

## 许可证

项目代码以 MIT 许可证提供。引入的标准测试集保留上游 Apache-2.0 许可证。
