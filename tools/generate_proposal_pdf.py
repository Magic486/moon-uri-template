"""Generate the one-page OSC 2026 project proposal PDF."""

from pathlib import Path

from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "moon-uri-template-project-proposal.pdf"
FONT_REGULAR = Path(r"C:\Windows\Fonts\msyh.ttc")
FONT_BOLD = Path(r"C:\Windows\Fonts\msyhbd.ttc")

NAVY = HexColor("#10243E")
BLUE = HexColor("#2563EB")
CYAN = HexColor("#21B6A8")
INK = HexColor("#172033")
MUTED = HexColor("#5B6678")
PALE = HexColor("#F3F7FC")
LINE = HexColor("#D9E3F0")


def wrap(canvas: Canvas, text: str, font: str, size: float, width: float):
    lines: list[str] = []
    current = ""
    for char in text:
        candidate = current + char
        if current and canvas.stringWidth(candidate, font, size) > width:
            lines.append(current)
            current = char
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def paragraph(
    canvas: Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    *,
    font: str = "MSYH",
    size: float = 8.4,
    leading: float = 12.2,
    color=INK,
) -> float:
    canvas.setFont(font, size)
    canvas.setFillColor(color)
    for line in wrap(canvas, text, font, size, width):
        canvas.drawString(x, y, line)
        y -= leading
    return y


def section_title(canvas: Canvas, number: str, title: str, x: float, y: float):
    canvas.setFillColor(BLUE)
    canvas.roundRect(x, y - 3, 18, 18, 5, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("MSYH-Bold", 8)
    canvas.drawCentredString(x + 9, y + 2.5, number)
    canvas.setFillColor(NAVY)
    canvas.setFont("MSYH-Bold", 11)
    canvas.drawString(x + 26, y, title)


def bullet(
    canvas: Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    *,
    color=INK,
) -> float:
    canvas.setFillColor(CYAN)
    canvas.circle(x + 3, y + 2.5, 2.2, fill=1, stroke=0)
    return paragraph(
        canvas,
        text,
        x + 12,
        y,
        width - 12,
        size=8.2,
        leading=11.6,
        color=color,
    ) - 2


def main():
    if not FONT_REGULAR.exists() or not FONT_BOLD.exists():
        raise SystemExit("Microsoft YaHei fonts are required to generate the PDF")
    pdfmetrics.registerFont(TTFont("MSYH", str(FONT_REGULAR), subfontIndex=0))
    pdfmetrics.registerFont(TTFont("MSYH-Bold", str(FONT_BOLD), subfontIndex=0))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    width, height = A4
    canvas = Canvas(str(OUTPUT), pagesize=A4)
    canvas.setTitle("moon-uri-template 项目申报书")
    canvas.setAuthor("moon-uri-template contributors")

    canvas.setFillColor(NAVY)
    canvas.rect(0, height - 126, width, 126, fill=1, stroke=0)
    canvas.setFillColor(CYAN)
    canvas.rect(0, height - 126, 8, 126, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("MSYH-Bold", 22)
    canvas.drawString(42, height - 53, "moon-uri-template")
    canvas.setFont("MSYH", 11.5)
    canvas.drawString(42, height - 78, "RFC 6570 Level 4 URI Template 的 MoonBit 完整实现")
    canvas.setFillColor(HexColor("#BFD4F4"))
    canvas.setFont("MSYH", 8.5)
    canvas.drawString(
        42,
        height - 103,
        "2026 MoonBit 国产基础软件生态开源大赛 · 8 月黑客松项目申报书",
    )

    margin = 42
    gap = 18
    col_width = (width - margin * 2 - gap) / 2
    left = margin
    right = margin + col_width + gap
    top = height - 154

    section_title(canvas, "01", "项目定位与生态价值", left, top)
    y = paragraph(
        canvas,
        "面向 HTTP 客户端、OpenAPI 工具、SDK 生成器与超媒体应用，提供标准化、可复用、跨后端的 URI Template 解析与展开能力，替代易出错的手工 URL 字符串拼接。",
        left,
        top - 27,
        col_width,
    )
    y -= 8
    canvas.setFillColor(PALE)
    canvas.roundRect(left, y - 62, col_width, 68, 7, fill=1, stroke=0)
    paragraph(
        canvas,
        "核心边界：只负责 RFC 6570 模板解析、校验与展开；不承担完整 URI 解析、HTTP 请求、权限控制或反向匹配。",
        left + 12,
        y - 10,
        col_width - 24,
        size=8.1,
        leading=11.5,
        color=MUTED,
    )
    y -= 82

    section_title(canvas, "02", "现有基础", left, y)
    y -= 27
    for item in [
        "已完成 Level 1-4、8 类操作符和 Prefix / Explode；支持标量、列表、关联数组。",
        "已实现 Unicode 码点前缀、UTF-8 百分号编码、JSON 适配器、结构化错误和资源上限。",
        "已提供 validate、variables、inspect、expand CLI 与真实 HTTP / SDK 请求构建示例。",
        "已引入上游 153 个一致性用例；当前 187 项测试在 4 个目标后端全部通过。",
    ]:
        y = bullet(canvas, item, left, y, col_width)

    section_title(canvas, "03", "计划新增与完善", right, top)
    y2 = top - 27
    for item in [
        "稳定公共 API 与错误模型，完善不可信模板的解析 / 输出限额和安全文档。",
        "扩充生成式边界测试，并与两个成熟 RFC 6570 实现持续进行逐字节差异验证。",
        "完善 HTTP / OpenAPI 风格集成示例、CLI 工作流、机器可读符合性报告和性能基线。",
        "完成 GitHub / Gitlink 协作、全后端 CI、mooncakes.io 发布、版本标签与长期维护说明。",
    ]:
        y2 = bullet(canvas, item, right, y2, col_width)

    y2 -= 3
    section_title(canvas, "04", "技术路线与验收证据", right, y2)
    y2 -= 27
    for item in [
        "架构：Scanner / Parser → 不可变模板模型 → Operator 规则表 → UTF-8 Encoder → Expander。",
        "正确性：RFC 正文示例 + 通用测试集 + 非法输入 + Unicode / 空值 / 顺序 / 确定性测试。",
        "工程化：moon fmt、moon check、moon info、全后端 build / test、可重复基准与 CI。",
        "交付物：MIT 开源仓库、完整 README、设计说明、测试与示例、CLI、mooncakes.io 包。",
    ]:
        y2 = bullet(canvas, item, right, y2, col_width)

    timeline_y = 306
    section_title(canvas, "05", "四周推进计划", margin, timeline_y)
    weeks = [
        ("W1", "API 与安全边界"),
        ("W2", "一致性与差异测试"),
        ("W3", "集成示例与性能"),
        ("W4", "发布、文档与验收"),
    ]
    week_gap = 8
    week_width = (width - margin * 2 - week_gap * 3) / 4
    for index, (week, task) in enumerate(weeks):
        x = margin + index * (week_width + week_gap)
        canvas.setFillColor(PALE)
        canvas.roundRect(x, timeline_y - 72, week_width, 50, 6, fill=1, stroke=0)
        canvas.setFillColor(BLUE if index % 2 == 0 else CYAN)
        canvas.setFont("MSYH-Bold", 8.5)
        canvas.drawString(x + 10, timeline_y - 41, week)
        canvas.setFillColor(INK)
        canvas.setFont("MSYH", 7.6)
        canvas.drawString(x + 10, timeline_y - 58, task)

    card_y = 104
    canvas.setFillColor(PALE)
    canvas.roundRect(margin, card_y, width - margin * 2, 72, 8, fill=1, stroke=0)
    metrics = [
        ("标准覆盖", "RFC 6570 L4"),
        ("上游用例", "153"),
        ("全后端测试", "187 × 4"),
        ("核心覆盖率", "99.43%"),
    ]
    cell_width = (width - margin * 2) / len(metrics)
    for index, (label, value) in enumerate(metrics):
        x = margin + index * cell_width
        if index:
            canvas.setStrokeColor(LINE)
            canvas.line(x, card_y + 14, x, card_y + 58)
        canvas.setFillColor(BLUE if index % 2 == 0 else CYAN)
        canvas.setFont("MSYH-Bold", 13)
        canvas.drawCentredString(x + cell_width / 2, card_y + 40, value)
        canvas.setFillColor(MUTED)
        canvas.setFont("MSYH", 7.5)
        canvas.drawCentredString(x + cell_width / 2, card_y + 21, label)

    canvas.setStrokeColor(LINE)
    canvas.line(margin, 78, width - margin, 78)
    canvas.setFillColor(MUTED)
    canvas.setFont("MSYH", 7.3)
    canvas.drawString(margin, 61, "暂定模块：yelfs/moon-uri-template · 许可证：MIT")
    canvas.drawRightString(width - margin, 61, "生成日期：2026-07-23")
    canvas.save()
    print(OUTPUT)


if __name__ == "__main__":
    main()
