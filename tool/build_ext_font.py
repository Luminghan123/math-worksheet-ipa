#!/usr/bin/env python3
"""生成 PDF 专用扩展中文字体（TrueType / glyf）。

背景
----
项目原来的 WorksheetCJK.ttf 是 SimHei 的 203 字子集，只含口算卷用到的字，
**不含语文生字、也不含带声调的拼音字母**（ā á ǎ à ... ǖ ǘ ǚ ǜ ü）。
而 pdf 包 3.11 的 Font.ttf() → TtfParser 只支持 TrueType `glyf`+`loca` 表，
系统里的 Noto CJK 却是 CFF/OTTO（`OTTO`），直接用会解析不出字形（PDF 空白）。

做法
----
1. 从 word_bank.dart 提取全部生字 + 全部拼音字母；
2. 加上生字卷/预览里会用到的固定中文文案、年级名、ASCII 与常用标点；
3. 从系统 NotoSerifCJK-Regular.ttc（简体）取字形，subset 子集化；
4. 用 cu2qu 把 CFF 三次曲线转成二次曲线，重建 glyf/loca/maxp/post 表，
   改 sfntVersion 为 TrueType，得到 pdf 包能读的 TTF。

产物：
  - assets/fonts/WorksheetCJK_Ext.ttf      （本机调试用二进制字体）
  - assets/fonts/WorksheetCJK_Ext.ttf.b64  （★ 随源码提交的 base64 文本，App 运行时解码）
依赖：fonttools（本地已装）；仅在本机运行一次，产物随源码提交。

补充：
  拼音「i 标调要去掉点」需要无点 i（U+0131 ı），但 Noto Serif CJK SC 没有此字形，
  故在子集化后从同系列 NotoSerif-Regular.ttf（同为 upem 1000 的衬线体）借一个
  dotlessi 字形补进 cmap/glyf/hmtx，使 PDF 与屏幕预览字形一致。
"""
import os
import re
import sys

from fontTools import subset
from fontTools.ttLib import TTFont, TTCollection, newTable
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANK = os.path.join(ROOT, 'lib', 'chinese', 'word_bank.dart')
OUT = os.path.join(ROOT, 'assets', 'fonts', 'WorksheetCJK_Ext.ttf')
SRC_TTC = '/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc'
MAX_ERR = 1.0

# 生字卷 / 预览 / 文件名里出现的固定中文（保证标题、页眉、页脚、按钮不缺字）
FIXED_TEXT = (
    '小学语文生字练习卷姓名班级日期用时得分共字页第'
    '练写字练拼音看拼音写生字看生字写拼音田字格四线三格'
    '年级上下一二三四五六数学口算题卡出题卡'
    '每页字数页数自定义生字练习卷保存另存为分享打印'
    '小学数学口算练习卷满分每题分试卷份道题'
    '请粘贴一课生字格式历史设置关于数据管理清空'
    '生成练习纸换一批上一页下一页保存到本地本机'
    '一年级二年级三年级四年级五年级六年级'
    '共页满分第页题每题分用时得分姓名日期'
)

# 常用标点 / 符号（同时把原字库的 203 个字符并进来，避免遗漏）
EXTRA_CHARS = (
    ' ·：，。、；！？（）【】「」《》—…　'
    '＋−×÷＝=/\\_~!@#$%^&*()[]{}<>|`"\';:,.?'
    '□○●△▲√×①②③④⑤⑥⑦⑧⑨⑩'
    'āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜüêê̄ếê̌ềńňǹḿ'
    'ı'  # U+0131 无点 i：拼音「i 标调去点」后字母主体要用，字体必须含此字形
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
)


def collect_chars():
    """从字表提取汉字与拼音字母，返回 unicode 码点集合。"""
    chars = set()
    with open(BANK, encoding='utf-8') as f:
        src = f.read()
    # '字:拼音' token
    for m in re.finditer(r"([\u3400-\u9fff]):([A-Za-z\u00c0-\u024f]+)", src):
        chars.add(ord(m.group(1)))
        for c in m.group(2):
            chars.add(ord(c))
    # 固定文案 + 额外符号 + ASCII
    for s in (FIXED_TEXT, EXTRA_CHARS):
        for c in s:
            if c != ' ':
                chars.add(ord(c))
    for cp in range(0x20, 0x7f):
        chars.add(cp)
    # 并入原字库 203 字符（口算卷若哪天也用这个字体，不会缺字）
    old = os.path.join(ROOT, 'assets', 'fonts', 'WorksheetCJK.ttf')
    if os.path.exists(old):
        oldfont = TTFont(old)
        for cp in (oldfont.getBestCmap() or {}):
            chars.add(cp)
        oldfont.close()
    return chars


def glyphs_to_quadratic(glyph_set, glyph_order, max_err=MAX_ERR):
    """CFF（三次）→ TrueType（二次）曲线转换。"""
    quad = {}
    for gname in glyph_order:
        tt_pen = TTGlyphPen(glyph_set)
        cu2qu = Cu2QuPen(tt_pen, max_err, reverse_direction=True)
        glyph_set[gname].draw(cu2qu)
        quad[gname] = tt_pen.glyph()
    return quad


def otf_to_ttf(font):
    assert font.sfntVersion == 'OTTO', font.sfntVersion
    assert 'CFF ' in font
    glyph_order = font.getGlyphOrder()
    glyph_set = font.getGlyphSet()

    font['loca'] = newTable('loca')
    font['glyf'] = glyf = newTable('glyf')
    glyf.glyphOrder = glyph_order
    glyf.glyphs = glyphs_to_quadratic(glyph_set, glyph_order)
    del font['CFF ']
    glyf.compile(font)

    # maxp 需升级到 1.0（TrueType），字段照规范填
    maxp = newTable('maxp')
    maxp.tableVersion = 0x00010000
    maxp.numGlyphs = len(glyph_order)
    maxp.maxPoints = 0
    maxp.maxContours = 0
    maxp.maxCompositePoints = 0
    maxp.maxCompositeContours = 0
    maxp.maxZones = 1
    maxp.maxTwilightPoints = 0
    maxp.maxStorage = 0
    maxp.maxFunctionDefs = 0
    maxp.maxInstructionDefs = 0
    maxp.maxStackElements = 0
    maxp.maxSizeOfInstructions = 0
    maxp.maxComponentElements = 0
    maxp.maxComponentDepth = 0
    font['maxp'] = maxp
    # 让 fontTools 依 glyf 重算 maxPoints 等
    maxp.recalc(font)

    post = font['post']
    post.formatType = 3.0  # 不需要字形名，最省空间且 pdf 包不读 post 字形名
    font['head'].indexToLocFormat = 0  # glyf.compile 会按需改成 1
    font.sfntVersion = '\x00\x01\x00\x00'
    return font


DONOR_TTF = '/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf'


def add_dotless_i(font):
    """把无点 i（U+0131 ı）补进目标字体。

    Noto Serif CJK SC 没有此字形，而拼音「i 标调要去掉点」需要它作为字母主体。
    借字来源 NotoSerif-Regular.ttf 同为 1000 upem 的衬线体、同为 TrueType glyf，
    dotlessi 是单轮廓简单字形，可直接搬过来，风格与其余拉丁字母一致。
    """
    src = TTFont(DONOR_TTF)
    src_cmap = src.getBestCmap() or {}
    gname = src_cmap.get(0x131)
    if gname is None:
        src.close()
        raise RuntimeError('donor font has no U+0131')
    glyph = src['glyf'][gname]
    adv, lsb = src['hmtx'][gname]

    order = list(font.getGlyphOrder())
    new = gname if gname not in order else 'dotlessi_ext'
    order.append(new)
    font.setGlyphOrder(order)
    font['glyf'].glyphOrder = order
    font['glyf'].glyphs[new] = glyph
    font['hmtx'].metrics[new] = (adv, lsb)
    font['maxp'].numGlyphs = len(order)
    for table in font['cmap'].tables:
        if table.isUnicode():
            table.cmap[0x131] = new
    src.close()
    print(f'injected U+0131 -> {new} (advance {adv})')


def main():
    chars = collect_chars()
    print(f'target codepoints: {len(chars)}')

    # 选简体 face：TTC 里 name 含 'SC' 的那个
    coll = TTCollection(SRC_TTC, lazy=False)
    face = None
    for i, f in enumerate(coll.fonts):
        names = f['name'].names
        label = ' '.join(
            n.toUnicode() for n in names if n.nameID in (1, 2, 4, 6)
        )
        if 'SC' in label or 'Simplified' in label or '简' in label:
            face = i
            print(f'pick face #{i}: {label[:80]}')
            break
    if face is None:
        face = 2  # Noto CJK 常见顺序 JP/KR/SC/TC/HK
        print('fallback face #2')
    font = coll.fonts[face]

    # 子集化（保留 cmap/name/head/hhea/hmtx/maxp/post/OS2）
    opts = subset.Options()
    opts.layout_features = []          # 不需要 GSUB/GPOS
    opts.name_IDs = ['*']
    opts.name_legacy = True
    opts.notdef_outline = True
    opts.recalc_bounds = True
    opts.drop_tables += ['GSUB', 'GPOS', 'GDEF', 'BASE', 'JSTF', 'DSIG',
                         'EBDT', 'EBLC', 'CBDT', 'CBLC', 'SVG ']
    sub = subset.Subsetter(options=opts)
    sub.populate(unicodes=chars)
    sub.subset(font)
    print(f'glyphs after subset: {len(font.getGlyphOrder())}')

    font = otf_to_ttf(font)
    # 补无点 i（U+0131）：拼音 i 标调要去掉点，字母主体需要这个字形
    add_dotless_i(font)
    # 删掉垂直排版表（vmtx/vhea/VORG）：PDF 横排完全用不到，且它们不含新增
    # 字形的度量，留着会在 save 时抛 KeyError。删掉还能再省几 KB。
    for tag in ('vmtx', 'vhea', 'VORG'):
        if tag in font:
            del font[tag]
    font['glyf'].compile(font)      # 重新生成 loca，纳入新增字形
    font['maxp'].recalc(font)
    font.save(OUT)
    font.close()
    coll.close()

    # 同时产出 base64 文本：工程以纯文本形式提交字体，App 运行时解码还原字节
    import base64
    with open(OUT, 'rb') as fh:
        encoded = base64.b64encode(fh.read()).decode('ascii')
    with open(OUT + '.b64', 'w', encoding='ascii') as fh:
        fh.write(encoded)
    print(f'base64 text: {OUT}.b64 ({os.path.getsize(OUT + ".b64")} bytes)')

    # 校验
    chk = TTFont(OUT)
    tables = set(chk.keys())
    need = {'head', 'name', 'hmtx', 'hhea', 'cmap', 'maxp', 'loca', 'glyf'}
    assert need.issubset(tables), f'missing tables: {need - tables}'
    assert chk.sfntVersion == '\x00\x01\x00\x00', chk.sfntVersion
    cmap = chk.getBestCmap() or {}
    cjk = [c for c in chars if 0x3400 <= c <= 0x9fff]
    missing = [c for c in cjk if c not in cmap]
    pin = 'āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü'
    missing_pin = [c for c in pin if ord(c) not in cmap]
    print(f'sfntVersion: {chk.sfntVersion!r} | tables: {sorted(need)}')
    print(f'cmap size: {len(cmap)} | CJK missing: {len(missing)} | '
          f'pinyin missing: {missing_pin}')
    print(f'dotless i (U+0131): {0x131 in cmap}')
    print(f'file size: {os.path.getsize(OUT)} bytes')
    chk.close()
    if missing or missing_pin or 0x131 not in cmap:
        print('WARN: some chars missing', file=sys.stderr)
        return 1
    print('OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())
