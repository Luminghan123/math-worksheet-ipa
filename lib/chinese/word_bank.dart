import '../engine.dart' show kGradeRules, gradeById;

/// ---------------------------------------------------------------------------
/// 内置分级生字表（1–6 年级共 12 册，每册 24 个常用字）
///
/// 数据格式：每个册一个字符串，用空格分隔「字:拼音」；拼音用带调号字母
/// （如 tiān、lǜ），与小学教材一致。这个格式刻意保持简单，方便：
///   1) Dart 侧解析成 Hanzi 列表；
///   2) 构建扩展字体时，用脚本从本文件提取「全部汉字 + 全部拼音字母」
///      作为子集化字符集，保证 PDF 里每个字、每个调号都能显示。
///
/// 【AI建议：这是一份按主题整理的示例字表，够生成练习纸用； V3 可替换为
///  按教材课文分课的真实字表，或直接由用户粘贴一课生字覆盖。】
/// ---------------------------------------------------------------------------

class Hanzi {
  /// 单个汉字
  final String char;

  /// 带调拼音（如 'tiān'）；自定义字查不到拼音时为空串
  final String pinyin;

  const Hanzi(this.char, this.pinyin);

  Map<String, dynamic> toJson() => {'c': char, 'p': pinyin};

  factory Hanzi.fromJson(Map<String, dynamic> j) => Hanzi(
        (j['c'] as String?) ?? '',
        (j['p'] as String?) ?? '',
      );
}

class HanziBank {
  HanziBank._();

  static const Map<String, String> _raw = {
    '1a': '一:yī 二:èr 三:sān 四:sì 五:wǔ 六:liù 七:qī 八:bā 九:jiǔ 十:shí '
        '上:shàng 下:xià 口:kǒu 耳:ěr 目:mù 手:shǒu 足:zú 日:rì 月:yuè '
        '水:shuǐ 火:huǒ 山:shān 石:shí 田:tián',
    '1b': '天:tiān 地:dì 人:rén 你:nǐ 我:wǒ 他:tā 大:dà 小:xiǎo 多:duō 少:shǎo '
        '白:bái 云:yún 风:fēng 雨:yǔ 花:huā 草:cǎo 树:shù 叶:yè '
        '鸟:niǎo 虫:chóng 鱼:yú 牛:niú 羊:yáng 马:mǎ',
    '2a': '春:chūn 夏:xià 秋:qiū 冬:dōng 雪:xuě 江:jiāng 河:hé 湖:hú 海:hǎi '
        '星:xīng 光:guāng 电:diàn 爸:bà 妈:mā 哥:gē 姐:jiě 弟:dì 妹:mèi '
        '爷:yé 奶:nǎi 门:mén 窗:chuāng 书:shū 笔:bǐ',
    '2b': '红:hóng 黄:huáng 绿:lǜ 蓝:lán 青:qīng 紫:zǐ 黑:hēi 高:gāo 长:cháng '
        '短:duǎn 前:qián 后:hòu 左:zuǒ 右:yòu 东:dōng 南:nán 西:xī 北:běi '
        '中:zhōng 早:zǎo 午:wǔ 晚:wǎn 夜:yè 本:běn',
    '3a': '字:zì 学:xué 校:xiào 老:lǎo 师:shī 同:tóng 友:yǒu 爱:ài 心:xīn 想:xiǎng '
        '说:shuō 读:dú 写:xiě 听:tīng 看:kàn 走:zǒu 跑:pǎo 跳:tiào 飞:fēi '
        '唱:chàng 画:huà 歌:gē 玩:wán 乐:lè',
    '3b': '清:qīng 晴:qíng 请:qǐng 情:qíng 生:shēng 气:qì 力:lì 方:fāng 向:xiàng '
        '道:dào 路:lù 桥:qiáo 车:chē 船:chuán 灯:dēng 站:zhàn 坐:zuò 立:lì '
        '行:xíng 开:kāi 关:guān 进:jìn 出:chū 时:shí',
    '4a': '峰:fēng 岭:lǐng 泉:quán 溪:xī 潭:tán 瀑:pù 林:lín 森:sēn 松:sōng '
        '柏:bǎi 竹:zhú 梅:méi 兰:lán 菊:jú 荷:hé 莲:lián 柳:liǔ 桃:táo '
        '杏:xìng 梨:lí 瓜:guā 果:guǒ 米:mǐ 麦:mài',
    '4b': '浪:làng 涛:tāo 潮:cháo 波:bō 纹:wén 静:jìng 动:dòng 快:kuài 慢:màn '
        '冷:lěng 热:rè 暖:nuǎn 凉:liáng 干:gān 湿:shī 甜:tián 苦:kǔ 香:xiāng '
        '酸:suān 辣:là 咸:xián 淡:dàn 深:shēn 浅:qiǎn',
    '5a': '勇:yǒng 敢:gǎn 坚:jiān 强:qiáng 诚:chéng 信:xìn 善:shàn 良:liáng '
        '勤:qín 奋:fèn 聪:cōng 智:zhì 慧:huì 德:dé 才:cái 志:zhì 愿:yuàn '
        '梦:mèng 希:xī 望:wàng 幸:xìng 福:fú 健:jiàn 康:kāng',
    '5b': '祖:zǔ 国:guó 宇:yǔ 宙:zhòu 世:shì 界:jiè 自:zì 然:rán 科:kē 技:jì '
        '历:lì 史:shǐ 文:wén 化:huà 艺:yì 术:shù 音:yīn 美:měi 篇:piān '
        '章:zhāng 句:jù 词:cí 语:yǔ 诗:shī 赋:fù',
    '6a': '观:guān 察:chá 思:sī 考:kǎo 判:pàn 断:duàn 研:yán 究:jiū 发:fā '
        '现:xiàn 创:chuàng 造:zào 设:shè 计:jì 规:guī 划:huà 管:guǎn 理:lǐ '
        '组:zǔ 织:zhī 协:xié 调:tiáo 沟:gōu 通:tōng 合:hé 作:zuò',
    '6b': '未:wèi 来:lái 青:qīng 春:chūn 岁:suì 月:yuè 阴:yīn 珍:zhēn 惜:xī '
        '留:liú 念:niàn 回:huí 忆:yì 温:wēn 情:qíng 谊:yì 感:gǎn 恩:ēn '
        '祝:zhù 美:měi 好:hǎo 圆:yuán 满:mǎn',
  };

  /// 取某一册的生字表
  static List<Hanzi> of(String gradeId) {
    final s = _raw[gradeId] ?? _raw['1a']!;
    return s
        .split(' ')
        .map((tok) {
          final i = tok.indexOf(':');
          if (i < 0) return const Hanzi('', '');
          return Hanzi(tok.substring(0, i), tok.substring(i + 1));
        })
        .where((h) => h.char.isNotEmpty)
        .toList();
  }

  /// 全字表「字 → 拼音」索引，供用户自定义粘贴的生字补拼音
  static final Map<String, String> pinyinIndex = <String, String>{
    for (final s in _raw.values)
      for (final tok in s.split(' '))
        if (tok.contains(':'))
          tok.substring(0, tok.indexOf(':')): tok.substring(tok.indexOf(':') + 1),
  };

  /// 年级册 id 列表（复用口算引擎的 12 档规则，label 也一致）
  static List<String> get gradeIds => kGradeRules.map((g) => g.id).toList();

  /// 年级册中文名，如「一年级上」
  static String labelOf(String id) => gradeById(id).label;
}
