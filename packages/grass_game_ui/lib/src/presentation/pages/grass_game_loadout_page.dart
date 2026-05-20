import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import '../../application/progression/grass_game_progress_controller.dart';
import '../widgets/animated_character_sprite.dart';

class GrassGameLoadoutPage extends StatefulWidget {
  const GrassGameLoadoutPage({
    super.key,
    required this.progressController,
    required this.onSettings,
    required this.onSkillGuide,
    required this.onStart,
    required this.onDeathmatchStart,
  });

  final GrassGameProgressController progressController;
  final VoidCallback onSettings;
  final VoidCallback onSkillGuide;
  final VoidCallback onStart;
  final VoidCallback onDeathmatchStart;

  @override
  State<GrassGameLoadoutPage> createState() => _GrassGameLoadoutPageState();
}

class _GrassGameLoadoutPageState extends State<GrassGameLoadoutPage> {
  String? _previewWeaponId;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final gameTheme = context.gameTheme;
    return Scaffold(
      backgroundColor: gameTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.progressController,
          builder: (context, _) {
            final progressController = widget.progressController;
            final previewWeapon = _previewWeapon(progressController);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    coins: progressController.coins,
                    level: progressController.profileLevel,
                    exp: progressController.profileExp,
                    requiredExp: progressController.requiredProfileExp,
                    expProgress: progressController.profileExpProgress,
                    title: strings.appTitle,
                    heroLevelLabel: strings.heroLevel(
                      progressController.profileLevel,
                    ),
                    onSettings: widget.onSettings,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: strings.character,
                    action: progressController.selectedCharacter.name,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final character = progressController.characters[index];
                        return _CharacterCard(
                          character: character,
                          isSelected: character.id ==
                              progressController.selectedCharacterId,
                          onTap: () {
                            final selected = progressController
                                .selectCharacter(character.id);
                            if (!selected) {
                              _showMessage(
                                  context, strings.locked(character.name));
                            }
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: progressController.characters.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SkillGuideEntry(
                    title: strings.skillGuide,
                    subtitle: strings.skillGuideSubtitle,
                    onOpen: widget.onSkillGuide,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: strings.weaponLoadout,
                    action: progressController.selectedWeapon.name,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _WeaponChooser(
                    progressController: progressController,
                    onPreview: _setPreviewWeapon,
                    onLocked: (weaponName) =>
                        _showMessage(context, strings.notOwned(weaponName)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _WeaponDetailPanel(
                    weapon: previewWeapon,
                    progress: progressController.progressFor(previewWeapon.id),
                    progressController: progressController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _WeaponShopEntry(
                    title: strings.weaponShop,
                    subtitle: strings.weaponsCount(
                      progressController.weapons.length,
                    ),
                    weaponCount: progressController.weapons.length,
                    onOpen: _openWeaponShop,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: widget.onStart,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: gameTheme.accent,
                            foregroundColor: gameTheme.ink,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(strings.startRun),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: widget.onDeathmatchStart,
                          icon: const Icon(Icons.local_fire_department_rounded),
                          label: Text(strings.deathmatch),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: gameTheme.hot,
                            side: BorderSide(color: gameTheme.hot),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  WeaponDefinition _previewWeapon(GrassGameProgressController controller) {
    final previewWeaponId = _previewWeaponId ?? controller.selectedWeaponId;
    return controller.weapons.firstWhere(
      (weapon) => weapon.id == previewWeaponId,
      orElse: () => controller.selectedWeapon,
    );
  }

  void _setPreviewWeapon(WeaponDefinition weapon) {
    setState(() {
      _previewWeaponId = weapon.id;
    });
  }

  Future<void> _openWeaponShop() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WeaponShopPage(
          progressController: widget.progressController,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _previewWeaponId = widget.progressController.selectedWeaponId;
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.coins,
    required this.level,
    required this.exp,
    required this.requiredExp,
    required this.expProgress,
    required this.title,
    required this.heroLevelLabel,
    required this.onSettings,
  });

  final int coins;
  final int level;
  final int exp;
  final int requiredExp;
  final double expProgress;
  final String title;
  final String heroLevelLabel;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: gameTheme.foreground,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _CoinPill(coins: coins),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: gameTheme.deep,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gameTheme.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        heroLevelLabel,
                        style: TextStyle(
                          color: gameTheme.foreground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$exp / $requiredExp EXP',
                        style: TextStyle(
                          color: gameTheme.muted,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProgressBar(value: expProgress, color: gameTheme.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.accent2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/game/grass_game/images/coins/coin_small.webp',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$coins',
              style: TextStyle(
                color: gameTheme.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinAmount extends StatelessWidget {
  const _CoinAmount({
    required this.amount,
    this.iconSize = 14,
    this.textColor,
  });

  final int amount;
  final double iconSize;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/game/grass_game/images/coins/coin_small.webp',
          width: iconSize,
          height: iconSize,
          filterQuality: FilterQuality.none,
        ),
        const SizedBox(width: 3),
        Text(
          '$amount',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor ?? gameTheme.foreground,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
  });

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: gameTheme.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Text(
            action,
            style: TextStyle(
              color: gameTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  final CharacterDefinition character;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final color = Color(character.colorValue);
    final speed = (character.baseSpeedMultiplier * 8).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? gameTheme.accent : gameTheme.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: character.isOwned
                        ? color.withOpacity(0.28)
                        : gameTheme.muted.withOpacity(0.22),
                    border: Border.all(
                      color: character.isOwned ? color : gameTheme.line,
                    ),
                  ),
                  child: Opacity(
                    opacity: character.isOwned ? 1 : 0.42,
                    child: Center(
                      child: AnimatedCharacterSprite(
                        spriteSheetAssetPath:
                            character.gameSpriteSheetAssetPath,
                        size: 38,
                        animate: character.isOwned && isSelected,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  character.isOwned
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  color: character.isOwned ? gameTheme.accent : gameTheme.muted,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              character.name,
              style: TextStyle(
                color: gameTheme.foreground,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              character.role,
              style: TextStyle(
                color: gameTheme.muted,
                fontSize: 12,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _StatLine(
              label: 'HP',
              text: '${character.baseHp}',
              value: character.baseHp / 140,
            ),
            const SizedBox(height: 3),
            _StatLine(
              label: 'SPD',
              text: '$speed',
              value: speed / 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.text,
    required this.value,
  });

  final String label;
  final String text;
  final double value;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            '$label $text',
            style: TextStyle(
              color: gameTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: _ProgressBar(
            value: value,
            color: gameTheme.foreground,
            height: 4,
          ),
        ),
      ],
    );
  }
}

class _WeaponChooser extends StatelessWidget {
  const _WeaponChooser({
    required this.progressController,
    required this.onPreview,
    required this.onLocked,
  });

  final GrassGameProgressController progressController;
  final ValueChanged<WeaponDefinition> onPreview;
  final ValueChanged<String> onLocked;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final ownedWeapons = progressController.weapons
        .where((weapon) => progressController.progressFor(weapon.id).isOwned)
        .toList(growable: false);
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final weapon = ownedWeapons[index];
          final progress = progressController.progressFor(weapon.id);
          final selected = weapon.id == progressController.selectedWeaponId;
          return _WeaponChip(
            weapon: weapon,
            progress: progress,
            isSelected: selected,
            onTap: () {
              onPreview(weapon);
              final ok = progressController.selectWeapon(weapon.id);
              if (!ok) {
                onLocked(strings.weaponName(weapon));
              }
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: ownedWeapons.length,
      ),
    );
  }
}

class _WeaponShopEntry extends StatelessWidget {
  const _WeaponShopEntry({
    required this.title,
    required this.subtitle,
    required this.weaponCount,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final int weaponCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gameTheme.deep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gameTheme.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gameTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: gameTheme.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: gameTheme.foreground,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: gameTheme.muted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: gameTheme.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillGuideEntry extends StatelessWidget {
  const _SkillGuideEntry({
    required this.title,
    required this.subtitle,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gameTheme.deep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gameTheme.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gameTheme.accent2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: gameTheme.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: gameTheme.foreground,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: gameTheme.muted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: gameTheme.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeaponDetailPanel extends StatelessWidget {
  const _WeaponDetailPanel({
    required this.weapon,
    required this.progress,
    required this.progressController,
  });

  final WeaponDefinition weapon;
  final WeaponProgress progress;
  final GrassGameProgressController progressController;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final gameTheme = context.gameTheme;
    final currentStats = progressController.weaponStatsFor(weapon.id);
    final nextStats = progress.isOwned && progress.level < weapon.maxLevel
        ? progressController.weaponStatsFor(
            weapon.id,
            level: progress.level + 1,
          )
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gameTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: 2,
                child: ColoredBox(
                  color: gameTheme.glass,
                  child: weapon.wikiImageUrl.isEmpty
                      ? _WeaponImageFallback(weapon: weapon)
                      : Image.network(
                          weapon.wikiImageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) {
                            return _WeaponImageFallback(weapon: weapon);
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    strings.weaponName(weapon),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gameTheme.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progress.isOwned
                      ? 'Lv ${progress.level}'
                      : strings.lockedLabel,
                  style: TextStyle(
                    color:
                        progress.isOwned ? gameTheme.accent : gameTheme.accent2,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WeaponCostPill(
                  label: strings.cost,
                  freeLabel: strings.free,
                  cost: weapon.buyCost,
                ),
                _WeaponMetaPill(
                    text: strings.weaponObtainType(weapon.obtainType)),
                _WeaponMetaPill(text: strings.weaponFamily(weapon.family)),
                _WeaponMetaPill(
                  text: strings.weaponAttackPattern(weapon.attackPattern),
                ),
                _WeaponMetaPill(
                    text: '${strings.damage} ${currentStats.damage}'),
                _WeaponMetaPill(
                  text: '${currentStats.attacksPerSecond.toStringAsFixed(2)}/s',
                ),
                _WeaponMetaPill(text: 'R ${currentStats.range.round()}'),
                _WeaponMetaPill(text: strings.weaponStars(weapon.maxStars)),
                _WeaponMetaPill(text: strings.weaponUnlockMethod(weapon)),
              ],
            ),
            const SizedBox(height: 10),
            _WeaponUpgradeStats(
              current: currentStats,
              next: nextStats,
              strings: strings,
            ),
            if (strings.weaponDescription(weapon).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                strings.weaponDescription(weapon),
                style: TextStyle(
                  color: gameTheme.muted,
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ],
            if (weapon.recipe != null) ...[
              const SizedBox(height: 8),
              Text(
                '${strings.recipe}: ${weapon.recipe!.materialWeaponIds.map((id) {
                  final material = progressController.weapons
                      .firstWhere((item) => item.id == id);
                  return strings.weaponName(material);
                }).join(' + ')}',
                style: TextStyle(
                  color: gameTheme.accent2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeaponUpgradeStats extends StatelessWidget {
  const _WeaponUpgradeStats({
    required this.current,
    required this.next,
    required this.strings,
  });

  final WeaponDisplayStats current;
  final WeaponDisplayStats? next;
  final _LoadoutStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: gameTheme.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            next == null
                ? strings.currentStatsTitle(current.level)
                : strings.nextUpgradeTitle(current.level, next!.level),
            style: TextStyle(
              color: gameTheme.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _WeaponUpgradeStatRow(
            label: strings.damage,
            currentValue: current.damage.toString(),
            nextValue: next?.damage.toString(),
          ),
          _WeaponUpgradeStatRow(
            label: strings.attackSpeed,
            currentValue: strings.perSecond(current.attacksPerSecond),
            nextValue:
                next == null ? null : strings.perSecond(next!.attacksPerSecond),
          ),
          _WeaponUpgradeStatRow(
            label: strings.range,
            currentValue: current.range.round().toString(),
            nextValue: next?.range.round().toString(),
          ),
        ],
      ),
    );
  }
}

class _WeaponUpgradeStatRow extends StatelessWidget {
  const _WeaponUpgradeStatRow({
    required this.label,
    required this.currentValue,
    required this.nextValue,
  });

  final String label;
  final String currentValue;
  final String? nextValue;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: gameTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            currentValue,
            style: TextStyle(
              color: gameTheme.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (nextValue != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: gameTheme.accent2,
              ),
            ),
            Text(
              nextValue!,
              style: TextStyle(
                color: gameTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeaponImageFallback extends StatelessWidget {
  const _WeaponImageFallback({required this.weapon});

  final WeaponDefinition weapon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        weapon.iconAssetPath,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _WeaponCostPill extends StatelessWidget {
  const _WeaponCostPill({
    required this.label,
    required this.freeLabel,
    required this.cost,
  });

  final String label;
  final String freeLabel;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.accent2.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gameTheme.accent2.withOpacity(0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: TextStyle(
                color: gameTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (cost <= 0)
              Text(
                freeLabel,
                style: TextStyle(
                  color: gameTheme.accent2,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              )
            else
              _CoinAmount(
                amount: cost,
                iconSize: 13,
                textColor: gameTheme.accent2,
              ),
          ],
        ),
      ),
    );
  }
}

class _WeaponMetaPill extends StatelessWidget {
  const _WeaponMetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gameTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: TextStyle(
            color: gameTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _WeaponChip extends StatelessWidget {
  const _WeaponChip({
    required this.weapon,
    required this.progress,
    required this.isSelected,
    required this.onTap,
  });

  final WeaponDefinition weapon;
  final WeaponProgress progress;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final gameTheme = context.gameTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? gameTheme.accent : gameTheme.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _WeaponIcon(weapon: weapon, isOwned: progress.isOwned),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    strings.weaponName(weapon),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gameTheme.foreground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    progress.isOwned
                        ? 'Lv ${progress.level}'
                        : strings.lockedLabel,
                    style: TextStyle(
                      color: gameTheme.muted,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeaponShopPage extends StatefulWidget {
  const _WeaponShopPage({required this.progressController});

  final GrassGameProgressController progressController;

  @override
  State<_WeaponShopPage> createState() => _WeaponShopPageState();
}

class _WeaponShopPageState extends State<_WeaponShopPage> {
  final Set<int> _expandedStars = {};

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final gameTheme = context.gameTheme;
    return Scaffold(
      backgroundColor: gameTheme.background,
      appBar: AppBar(
        backgroundColor: gameTheme.background,
        foregroundColor: gameTheme.foreground,
        title: Text(strings.weaponShop),
        actions: [
          AnimatedBuilder(
            animation: widget.progressController,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: _CoinPill(coins: widget.progressController.coins),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: widget.progressController,
          builder: (context, _) {
            final groups = _weaponGroupsByStars();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      for (final entry in groups.entries) ...[
                        SliverToBoxAdapter(
                          child: _WeaponStarHeader(
                            stars: entry.key,
                            count: entry.value.length,
                            isExpanded: _expandedStars.contains(entry.key),
                            onTap: () => _toggleStars(entry.key),
                          ),
                        ),
                        if (_expandedStars.contains(entry.key))
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 10, bottom: 12),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.58,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                final weapon = entry.value[index];
                                final progress = widget.progressController
                                    .progressFor(weapon.id);
                                return _WeaponGridTile(
                                  weapon: weapon,
                                  progress: progress,
                                  isSelected: weapon.id ==
                                      widget
                                          .progressController.selectedWeaponId,
                                  onTap: () =>
                                      _showWeaponDialog(context, weapon),
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<int, List<WeaponDefinition>> _weaponGroupsByStars() {
    final groups = <int, List<WeaponDefinition>>{};
    final weaponOrder = <String, int>{};
    for (var index = 0;
        index < widget.progressController.weapons.length;
        index++) {
      final weapon = widget.progressController.weapons[index];
      weaponOrder[weapon.id] = index;
      groups.putIfAbsent(weapon.maxStars, () => []).add(weapon);
    }
    for (final weapons in groups.values) {
      weapons.sort((a, b) {
        final aOwned = widget.progressController.progressFor(a.id).isOwned;
        final bOwned = widget.progressController.progressFor(b.id).isOwned;
        if (aOwned != bOwned) {
          return aOwned ? -1 : 1;
        }
        return (weaponOrder[a.id] ?? 0).compareTo(weaponOrder[b.id] ?? 0);
      });
    }
    return Map.fromEntries(
      groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _toggleStars(int stars) {
    setState(() {
      if (!_expandedStars.add(stars)) {
        _expandedStars.remove(stars);
      }
    });
  }

  void _showWeaponDialog(BuildContext context, WeaponDefinition weapon) {
    final strings = _LoadoutStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: widget.progressController,
          builder: (context, _) {
            final progress = widget.progressController.progressFor(weapon.id);
            final upgradeCost =
                widget.progressController.upgradeCost(weapon.id);
            final canUpgrade =
                progress.isOwned && progress.level < weapon.maxLevel;
            final isCraftWeapon = weapon.recipe != null;
            final actionCost = isCraftWeapon
                ? widget.progressController.craftCost(weapon.id)
                : weapon.buyCost;
            final gameTheme = context.gameTheme;
            return Dialog(
              backgroundColor: gameTheme.deep,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WeaponDetailPanel(
                        weapon: weapon,
                        progress: progress,
                        progressController: widget.progressController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(strings.close),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (progress.isOwned) {
                                  widget.progressController
                                      .selectWeapon(weapon.id);
                                  Navigator.of(dialogContext).pop();
                                  return;
                                }
                                final ok = isCraftWeapon
                                    ? widget.progressController
                                        .craftWeapon(weapon.id)
                                    : widget.progressController
                                        .buyWeapon(weapon.id);
                                if (!ok) {
                                  final missing = isCraftWeapon
                                      ? widget.progressController
                                          .missingCraftMaterialIds(weapon.id)
                                      : const <String>[];
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          missing.isEmpty
                                              ? strings.notEnoughCoins
                                              : strings.missingMaterials,
                                        ),
                                      ),
                                    );
                                }
                              },
                              child: progress.isOwned
                                  ? Text(strings.select)
                                  : _CostButtonLabel(
                                      label: isCraftWeapon
                                          ? strings.craft
                                          : strings.buy,
                                      cost: actionCost,
                                    ),
                            ),
                          ),
                          if (progress.isOwned) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: canUpgrade
                                    ? () {
                                        final before = widget.progressController
                                            .weaponStatsFor(weapon.id);
                                        final ok = widget.progressController
                                            .upgradeWeapon(weapon.id);
                                        if (!ok) {
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    strings.notEnoughCoins),
                                              ),
                                            );
                                          return;
                                        }
                                        final after = widget.progressController
                                            .weaponStatsFor(weapon.id);
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                strings.upgradeResult(
                                                  before: before,
                                                  after: after,
                                                ),
                                              ),
                                            ),
                                          );
                                      }
                                    : null,
                                child: _CostButtonLabel(
                                  label: canUpgrade
                                      ? strings.upgrade
                                      : strings.maxLevel,
                                  cost: upgradeCost,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeaponStarHeader extends StatelessWidget {
  const _WeaponStarHeader({
    required this.stars,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final int stars;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: gameTheme.deep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gameTheme.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < stars; index++)
                      Icon(
                        Icons.star_rounded,
                        color: gameTheme.accent2,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$stars Star',
                      style: TextStyle(
                        color: gameTheme.foreground,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: gameTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: gameTheme.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeaponGridTile extends StatelessWidget {
  const _WeaponGridTile({
    required this.weapon,
    required this.progress,
    required this.isSelected,
    required this.onTap,
  });

  final WeaponDefinition weapon;
  final WeaponProgress progress;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    final gameTheme = context.gameTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? gameTheme.accent : gameTheme.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _WeaponIcon(
                weapon: weapon,
                isOwned: progress.isOwned,
                size: 72,
                imageSize: 64,
                lockSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.weaponName(weapon),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            _WeaponTileStatus(
              progress: progress,
              cost: weapon.buyCost,
              buyLabel: strings.buy,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeaponTileStatus extends StatelessWidget {
  const _WeaponTileStatus({
    required this.progress,
    required this.cost,
    required this.buyLabel,
  });

  final WeaponProgress progress;
  final int cost;
  final String buyLabel;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    if (progress.isOwned) {
      return Text(
        'Lv ${progress.level}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: gameTheme.accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buyLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: gameTheme.accent2,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 4),
          _CoinAmount(
            amount: cost,
            iconSize: 12,
            textColor: gameTheme.accent2,
          ),
        ],
      ),
    );
  }
}

class _CostButtonLabel extends StatelessWidget {
  const _CostButtonLabel({
    required this.label,
    required this.cost,
  });

  final String label;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onPrimary;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (cost > 0) ...[
            const SizedBox(width: 5),
            _CoinAmount(
              amount: cost,
              iconSize: 14,
              textColor: textColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeaponIcon extends StatelessWidget {
  const _WeaponIcon({
    required this.weapon,
    required this.isOwned,
    this.size = 42,
    this.imageSize = 36,
    this.lockSize = 16,
  });

  final WeaponDefinition weapon;
  final bool isOwned;
  final double size;
  final double imageSize;
  final double lockSize;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOwned
            ? Color(weapon.baseColorValue)
            : Color(weapon.baseColorValue).withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            weapon.iconAssetPath,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
          if (!isOwned)
            Positioned(
              right: 2,
              bottom: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: gameTheme.glass,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: gameTheme.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.lock_rounded,
                    color: gameTheme.foreground,
                    size: lockSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    this.height = 7,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: gameTheme.line,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadoutStrings {
  const _LoadoutStrings(this.isZh);

  factory _LoadoutStrings.of(BuildContext context) {
    return _LoadoutStrings(
        Localizations.localeOf(context).languageCode == 'zh');
  }

  final bool isZh;

  String get appTitle => isZh ? 'ODT 生存' : 'ODT Run';
  String get character => isZh ? '角色' : 'Character';
  String get skillGuide => isZh ? '技能图鉴' : 'Skill Guide';
  String get skillGuideSubtitle =>
      isZh ? '查看技能树、核心进化与终极大招' : 'Skill trees, evolutions, and ultimates';
  String get weaponLoadout => isZh ? '武器配置' : 'Weapon Loadout';
  String get weaponShop => isZh ? '武器商店' : 'Weapon Shop';
  String get startRun => isZh ? '开始作战' : 'Start Run';
  String get deathmatch => isZh ? '死斗模式' : 'Deathmatch';
  String get lockedLabel => isZh ? '未拥有' : 'Locked';
  String get close => isZh ? '关闭' : 'Close';
  String get select => isZh ? '选择' : 'Select';
  String get buy => isZh ? '购买' : 'Buy';
  String get craft => isZh ? '合成' : 'Craft';
  String get upgrade => isZh ? '升级' : 'Upgrade';
  String get maxLevel => isZh ? '已满级' : 'Max Lv';
  String get cost => isZh ? '价格' : 'Cost';
  String get damage => isZh ? '伤害' : 'Damage';
  String get attackSpeed => isZh ? '射速' : 'Fire Rate';
  String get range => isZh ? '范围' : 'Range';
  String get recipe => isZh ? '配方' : 'Recipe';
  String get free => isZh ? '免费' : 'Free';
  String get notEnoughCoins => isZh ? '金币不足' : 'Not enough coins';
  String get missingMaterials => isZh ? '配方武器未拥有' : 'Missing recipe weapons';

  String heroLevel(int level) => isZh ? '英雄等级 $level' : 'Hero Lv $level';

  String weaponsCount(int count) {
    return isZh ? '$count 把武器 · 宫格展示' : '$count weapons · Grid view';
  }

  String locked(String name) => isZh ? '$name 尚未解锁' : '$name is locked';

  String notOwned(String name) => isZh ? '$name 尚未拥有' : '$name is not owned';

  String weaponName(WeaponDefinition weapon) {
    if (isZh) {
      return weapon.name;
    }
    return switch (weapon.id) {
      'wooden_stick' => 'Wooden Stick',
      'bounce_ball' => 'Bounce Ball',
      'star_dart' => 'Star Dart',
      'magnet_bow' => 'Magnet Bow',
      'return_sickle' => 'Return Sickle',
      'spark_pistol' => 'Spark Pistol',
      'frost_staff' => 'Frost Staff',
      'scatter_blunder' => 'Scatter Blunder',
      'thunder_needle' => 'Thunder Needle',
      'flame_sprayer' => 'Flame Sprayer',
      'mini_grenade' => 'Mini Grenade',
      'ball_hammer' => 'Ball Hammer',
      'moon_sickle' => 'Moon Sickle',
      'storm_ball' => 'Storm Ball',
      'flame_scatter' => 'Flame Scatter',
      'ice_moon' => 'Ice Moon',
      'storm_hammer' => 'Storm Hammer',
      'star_core_cannon' => 'Star Core Cannon',
      _ => weapon.name,
    };
  }

  String weaponDescription(WeaponDefinition weapon) {
    if (isZh) {
      return weapon.description;
    }
    return switch (weapon.id) {
      'wooden_stick' => 'A reliable starter sweep for close-range control.',
      'bounce_ball' => 'Bounces through side lanes while kiting enemies.',
      'star_dart' => 'Fast piercing shots for stable line clearing.',
      'magnet_bow' => 'Long-range steady damage for slower heroes.',
      'return_sickle' =>
        'Two-pass cutting damage on the outbound and return path.',
      'spark_pistol' => 'High fire rate and low recoil for early waves.',
      'frost_staff' => 'Slows enemies and creates safer spacing.',
      'scatter_blunder' => 'Wide burst damage against dense front lines.',
      'thunder_needle' => 'Chains damage into nearby packed enemies.',
      'flame_sprayer' => 'Short-range flame pressure for continuous clearing.',
      'mini_grenade' => 'Lobs explosive shots into grouped enemies.',
      'ball_hammer' => 'Crafted heavy impact with strong knockback.',
      'moon_sickle' => 'Crafted sweeping blade with broad close control.',
      'storm_ball' => 'Crafted bouncing energy for sustained pressure.',
      'flame_scatter' => 'Crafted fire burst for wide-area clearing.',
      'ice_moon' => 'Orbiting ice blade that slows and cuts nearby enemies.',
      'storm_hammer' => 'Heavy storm impact with chained pressure.',
      'star_core_cannon' => 'Endgame explosive core cannon.',
      _ => weapon.description,
    };
  }

  String weaponFamily(WeaponFamily family) {
    if (isZh) {
      return family.label;
    }
    return switch (family) {
      WeaponFamily.melee => 'Melee',
      WeaponFamily.projectile => 'Projectile',
      WeaponFamily.firearm => 'Firearm',
      WeaponFamily.energy => 'Energy',
      WeaponFamily.explosive => 'Explosive',
      WeaponFamily.control => 'Control',
    };
  }

  String weaponAttackPattern(WeaponAttackPattern pattern) {
    if (isZh) {
      return pattern.label;
    }
    return switch (pattern) {
      WeaponAttackPattern.meleeSweep => 'Sweep',
      WeaponAttackPattern.projectile => 'Straight Shot',
      WeaponAttackPattern.bouncingProjectile => 'Bounce',
      WeaponAttackPattern.boomerang => 'Boomerang',
      WeaponAttackPattern.coneShot => 'Cone Shot',
      WeaponAttackPattern.beam => 'Beam',
      WeaponAttackPattern.lobbedExplosion => 'Lobbed Blast',
      WeaponAttackPattern.chainLightning => 'Chain Lightning',
      WeaponAttackPattern.flameStream => 'Flame Stream',
      WeaponAttackPattern.orbitSlash => 'Orbit Slash',
    };
  }

  String weaponObtainType(WeaponObtainType obtainType) {
    if (isZh) {
      return obtainType.label;
    }
    return switch (obtainType) {
      WeaponObtainType.free => 'Free',
      WeaponObtainType.shop => 'Shop',
      WeaponObtainType.craft => 'Craft',
      WeaponObtainType.ultimateCraft => 'Ultimate Craft',
    };
  }

  String weaponUnlockMethod(WeaponDefinition weapon) {
    if (weapon.recipe == null) {
      return weaponObtainType(weapon.obtainType);
    }
    return isZh ? '配方合成' : 'Recipe Craft';
  }

  String weaponStars(int count) {
    return isZh ? '$count 星' : '$count Stars';
  }

  String currentStatsTitle(int level) {
    return isZh ? '当前数值 · Lv $level' : 'Current Stats · Lv $level';
  }

  String nextUpgradeTitle(int currentLevel, int nextLevel) {
    return isZh
        ? '下次升级 · Lv $currentLevel -> Lv $nextLevel'
        : 'Next Upgrade · Lv $currentLevel -> Lv $nextLevel';
  }

  String perSecond(double value) => '${value.toStringAsFixed(2)}/s';

  String upgradeResult({
    required WeaponDisplayStats before,
    required WeaponDisplayStats after,
  }) {
    final base = isZh
        ? '升级成功 Lv ${before.level} -> ${after.level}'
        : 'Upgraded Lv ${before.level} -> ${after.level}';
    return '$base · ${isZh ? '伤害' : 'DMG'} ${before.damage}->${after.damage} · '
        '${isZh ? '射速' : 'SPD'} ${perSecond(before.attacksPerSecond)}->${perSecond(after.attacksPerSecond)} · '
        '${isZh ? '范围' : 'RNG'} ${before.range.round()}->${after.range.round()}';
  }
}
