import 'package:flutter/material.dart';

import '../app_theme.dart';

/// ---------------------------------------------------------------------------
/// 可复用 UI 组件：分组卡片 / 分组标题 / 表单行 / 步进器 / 标签芯片 / 主按钮
/// 对应旧版 index.html 的 .group / .g-head / .frow / .stepper / .chip / .primary
/// ---------------------------------------------------------------------------

class GroupCard extends StatelessWidget {
  final Widget child;
  const GroupCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12002060), blurRadius: 22, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class GroupHead extends StatelessWidget {
  final String badge;
  final String title;
  final String? tag;
  final Color badgeColor;
  final Color badgeBg;
  const GroupHead({
    super.key,
    required this.badge,
    required this.title,
    this.tag,
    this.badgeColor = kBrand,
    this.badgeBg = kSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(badge,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: badgeColor)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
        ),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: kSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(tag!,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: kBrand)),
          ),
      ],
    );
  }
}

class HintText extends StatelessWidget {
  final String text;
  const HintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: kInk3, height: 1.6)),
    );
  }
}

/// 一行：左标签 / 右控件，垂直居中、等高、带分隔线
class FormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool showTopLine;
  const FormRow({
    super.key,
    required this.label,
    required this.child,
    this.showTopLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: showTopLine
            ? const Border(top: BorderSide(color: kLine, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: kInk, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// − 值 + 步进器
class NumberStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const NumberStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration:
          BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('−', onMinus),
          SizedBox(
            width: 30,
            child: Center(
              child: Text('$value',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            ),
          ),
          _btn('+', onPlus),
        ],
      ),
    );
  }

  Widget _btn(String t, VoidCallback cb) {
    return InkWell(
      onTap: cb,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(t,
            style: const TextStyle(
                fontSize: 17, color: kBrand, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// 可多选的胶囊标签
class ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? kGrad : null,
          color: selected ? null : kBg,
          border: selected ? null : Border.all(color: kLine),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x474C63E6),
                      blurRadius: 12,
                      offset: Offset(0, 4))
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : kInk2)),
      ),
    );
  }
}

/// 分段选择（PDF 整卷 / 打印预览）
class SegChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SegChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? kGrad : null,
            color: selected ? null : kBg,
            border: selected ? null : Border.all(color: kLine),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kInk2)),
        ),
      ),
    );
  }
}

/// 渐变主按钮
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool busy;
  final VoidCallback? onTap;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: kGrad,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x524C63E6), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.transparent,
          ),
          onPressed: busy ? null : onTap,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 底部固定的主按钮栏
class FooterBar extends StatelessWidget {
  final Widget child;
  const FooterBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kLine, width: 1)),
      ),
      child: child,
    );
  }
}
