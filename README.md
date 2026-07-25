# moon-uri-template

基于 MoonBit 纯实现的 [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) Level 4 URI Template 库。

支持全部 RFC 6570 操作符、prefix 与 explode 修饰符、有序标量/列表/关联数组值、
Unicode 码点感知截取、UTF-8 百分号编码、结构化错误、JSON 变量适配器及 CLI 工具。

命名空间：`Magic486/moon-uri-template`。

## 安装

首个 mooncakes.io 版本发布前，请克隆仓库并执行 `moon update`。确认命名空间后，
最终 `moon add` 命令将在此处更新。

## 示例

```mbt
let template = @moon-uri-template.UriTemplate::parse(
  "/repos/{owner}/{repo}/issues{?page,labels*}",
)
let variables : Map[String, @moon-uri-template.UriValue] = {
  "owner": Scalar("moonbitlang"),
  "repo": Scalar("core"),
  "page": Scalar("2"),
  "labels": List(["bug", "help wanted"]),
}
let uri = template.expand(variables)
```

结果：

```text
/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted
```

## CLI

```bash
moon run cmd/uri-template -- validate '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- variables '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- inspect '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- expand \
  '/repos/{owner}/{repo}/issues{?page,labels*}' \
  --variables examples/variables.json
```

## 验证

项目引入了 Apache-2.0 许可的
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
测试集（固定于 commit `4171dac22aa67fc710b3f6df308a50bd08552986`）。
生成的测试套件贡献 153 个互操作性用例。
[conformance-summary.json](conformance-summary.json) 记录了测试数据和预期拒绝计数。

```bash
moon check --warn-list +73
moon test --target all
moon fmt --check
moon info
```

完整的公开指南（含可运行测试示例）见 [README.mbt.md](README.mbt.md)。
规范范围见 [SPEC.md](docs/SPEC.md)，里程碑见 [GOALS.md](docs/GOALS.md)，
第三方声明见 [THIRD_PARTY.md](docs/THIRD_PARTY.md)。
可复现的性能基准见 [BENCHMARKS.md](docs/BENCHMARKS.md)。
[差异测试](docs/DIFFERENTIAL_TESTING.md) 与两个独立维护的实现逐字节对比展开结果。
项目申报书见 [output/pdf/moon-uri-template-project-proposal.pdf](output/pdf/moon-uri-template-project-proposal.pdf)。
发布与 GitHub 同步步骤见 [RELEASING.md](docs/RELEASING.md)。

## 资源限制

`UriTemplate::parse` 使用文档化的默认值：最大 1 MiB 模板长度、4096 个表达式、
每个表达式 256 个变量。接受不可信模板的应用可调用 `UriTemplate::parse_with_limits`
设置更小的每次调用上限。`UriTemplate::expand` 限制输出为 1 MiB；
`expand_with_limit` 接受显式的更小或更大上限。不使用全局可变配置。

[HTTP 客户端示例](examples/http-client/main.mbt) 展示了 SDK 请求模型如何将
类型化字段映射到 RFC 6570 端点：

```bash
moon run examples/http-client
```

## 安全边界

URI Template 展开不是输入校验。尤其 `{+var}` 和 `{#var}` 刻意允许 URI 保留字符。
在对不可信展开值发起 SSRF 敏感网络请求前，请应用独立的 scheme/host/port 目标策略。
结构化错误不会回显完整变量集合。

## 许可证

项目代码采用 MIT 许可证。引入的标准测试集保留 Apache-2.0 许可证。
