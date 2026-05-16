import 'package:flutter/material.dart';

import '../../application/progression/grass_game_progress_controller.dart';

class GrassGameLoadoutPage extends StatefulWidget {
  const GrassGameLoadoutPage({
    super.key,
    required this.progressController,
    required this.onSettings,
    required this.onStart,
  });

  final GrassGameProgressController progressController;
  final VoidCallback onSettings;
  final VoidCallback onStart;

  @override
  State<GrassGameLoadoutPage> createState() => _GrassGameLoadoutPageState();
}

class _GrassGameLoadoutPageState extends State<GrassGameLoadoutPage> {
  String? _previewWeaponId;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF07130D),
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
                    height: 166,
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
                    child: FilledButton(
                      onPressed: widget.onStart,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: const Color(0xFF49D17D),
                        foregroundColor: const Color(0xFF07130D),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE8FFF2),
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
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
              color: const Color(0xFF102418),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x3349D17D)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        heroLevelLabel,
                        style: const TextStyle(
                          color: Color(0xFFE8FFF2),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$exp / $requiredExp EXP',
                        style: const TextStyle(
                          color: Color(0xBFE8FFF2),
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProgressBar(
                      value: expProgress, color: const Color(0xFF49D17D)),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Image.asset(
              'assets/game/grass_game/images/coins/coin_small.webp',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$coins',
              style: const TextStyle(
                color: Color(0xFF07130D),
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
    this.textColor = const Color(0xFFE8FFF2),
  });

  final int amount;
  final double iconSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
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
            color: textColor,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8FFF2),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Text(
            action,
            style: const TextStyle(
              color: Color(0x9949D17D),
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
    final color = Color(character.colorValue);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF49D17D) : const Color(0x3349D17D),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: character.isOwned
                        ? color.withOpacity(0.28)
                        : const Color(0xFF3B4540),
                    border: Border.all(
                      color:
                          character.isOwned ? color : const Color(0x66525F59),
                    ),
                  ),
                  child: Opacity(
                    opacity: character.isOwned ? 1 : 0.42,
                    child: Image.asset(
                      isSelected
                          ? character.walkPreviewAssetPath
                          : character.avatarAssetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  character.isOwned
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  color: character.isOwned
                      ? const Color(0xFF49D17D)
                      : const Color(0x99E8FFF2),
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              character.name,
              style: const TextStyle(
                color: Color(0xFFE8FFF2),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            Text(
              character.role,
              style: const TextStyle(
                color: Color(0x99E8FFF2),
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            _StatLine(label: 'HP', value: character.baseHp / 140),
            const SizedBox(height: 5),
            _StatLine(label: 'SPD', value: character.baseSpeedMultiplier / 1.2),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0x99E8FFF2),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: _ProgressBar(
            value: value,
            color: const Color(0xFFE8FFF2),
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
                onLocked(weapon.name);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF102418),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x3349D17D)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF49D17D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF07130D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFE8FFF2),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0x99E8FFF2),
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE8FFF2),
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
  });

  final WeaponDefinition weapon;
  final WeaponProgress progress;

  @override
  Widget build(BuildContext context) {
    final strings = _LoadoutStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x3349D17D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: 2,
                child: ColoredBox(
                  color: const Color(0xFF07130D),
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
                    weapon.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8FFF2),
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
                    color: progress.isOwned
                        ? const Color(0xFF49D17D)
                        : const Color(0xFFFFC857),
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
                _WeaponMetaPill(text: weapon.country),
                _WeaponMetaPill(text: weapon.kind),
                _WeaponMetaPill(text: weapon.fireMode),
                _WeaponMetaPill(text: '${strings.damage} ${weapon.damage}'),
                _WeaponMetaPill(text: '${weapon.fireRateRoundsPerMinute} RPM'),
                _WeaponMetaPill(text: '${weapon.maxStars} Stars'),
                _WeaponMetaPill(text: weapon.unlockMethod),
              ],
            ),
          ],
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x26FFC857),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x66FFC857)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: const TextStyle(
                color: Color(0xBFE8FFF2),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (cost <= 0)
              Text(
                freeLabel,
                style: const TextStyle(
                  color: Color(0xFFFFC857),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              )
            else
              _CoinAmount(
                amount: cost,
                iconSize: 13,
                textColor: const Color(0xFFFFC857),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x2249D17D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xBFE8FFF2),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF49D17D) : const Color(0x3349D17D),
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
                    weapon.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8FFF2),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    progress.isOwned
                        ? 'Lv ${progress.level}'
                        : strings.lockedLabel,
                    style: const TextStyle(
                      color: Color(0x99E8FFF2),
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
    return Scaffold(
      backgroundColor: const Color(0xFF07130D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07130D),
        foregroundColor: const Color(0xFFE8FFF2),
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
                                childAspectRatio: 0.82,
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
            return Dialog(
              backgroundColor: const Color(0xFF102418),
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
                      _WeaponDetailPanel(weapon: weapon, progress: progress),
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
                                final ok = widget.progressController
                                    .buyWeapon(weapon.id);
                                if (!ok) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(strings.notEnoughCoins),
                                      ),
                                    );
                                }
                              },
                              child: progress.isOwned
                                  ? Text(strings.select)
                                  : _CostButtonLabel(
                                      label: strings.buy,
                                      cost: weapon.buyCost,
                                    ),
                            ),
                          ),
                          if (progress.isOwned) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () {
                                  final ok = widget.progressController
                                      .upgradeWeapon(weapon.id);
                                  if (!ok) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(strings.notEnoughCoins),
                                        ),
                                      );
                                  }
                                },
                                child: _CostButtonLabel(
                                  label: strings.upgrade,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF102418),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x3349D17D)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < stars; index++)
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC857),
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$stars Star',
                      style: const TextStyle(
                        color: Color(0xFFE8FFF2),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0x9949D17D),
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
                color: const Color(0xFFE8FFF2),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF49D17D) : const Color(0x3349D17D),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _WeaponIcon(weapon: weapon, isOwned: progress.isOwned),
            ),
            const SizedBox(height: 8),
            Text(
              weapon.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE8FFF2),
                fontSize: 12,
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
    if (progress.isOwned) {
      return Text(
        'Lv ${progress.level}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF49D17D),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }

    return Row(
      children: [
        Text(
          buyLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFFFC857),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: _CoinAmount(
            amount: cost,
            iconSize: 12,
            textColor: const Color(0xFFFFC857),
          ),
        ),
      ],
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          _CoinAmount(
            amount: cost,
            iconSize: 14,
            textColor: const Color(0xFFFFFFFF),
          ),
        ],
      ),
    );
  }
}

class _WeaponIcon extends StatelessWidget {
  const _WeaponIcon({
    required this.weapon,
    required this.isOwned,
  });

  final WeaponDefinition weapon;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isOwned ? Color(weapon.baseColorValue) : const Color(0xFF3B4540),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isOwned ? 1 : 0.34,
            child: Image.asset(
              weapon.iconAssetPath,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          if (!isOwned)
            const Icon(
              Icons.lock_rounded,
              color: Color(0xFFE8FFF2),
              size: 16,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: const Color(0x22FFFFFF),
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
  String get weaponLoadout => isZh ? '武器配置' : 'Weapon Loadout';
  String get weaponShop => isZh ? '武器商店' : 'Weapon Shop';
  String get startRun => isZh ? '开始作战' : 'Start Run';
  String get lockedLabel => isZh ? '未拥有' : 'Locked';
  String get close => isZh ? '关闭' : 'Close';
  String get select => isZh ? '选择' : 'Select';
  String get buy => isZh ? '购买' : 'Buy';
  String get upgrade => isZh ? '升级' : 'Upgrade';
  String get cost => isZh ? '价格' : 'Cost';
  String get damage => isZh ? '伤害' : 'Damage';
  String get free => isZh ? '免费' : 'Free';
  String get notEnoughCoins => isZh ? '金币不足' : 'Not enough coins';

  String heroLevel(int level) => isZh ? '英雄等级 $level' : 'Hero Lv $level';

  String weaponsCount(int count) {
    return isZh ? '$count 把武器 · 宫格展示' : '$count weapons · Grid view';
  }

  String locked(String name) => isZh ? '$name 尚未解锁' : '$name is locked';

  String notOwned(String name) => isZh ? '$name 尚未拥有' : '$name is not owned';
}
