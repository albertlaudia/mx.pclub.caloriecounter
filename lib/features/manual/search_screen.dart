import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/food_item.dart';
import '../../shared/providers/providers.dart';

/// Manual food search — debounced local DB lookup + online fallback.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<FoodItem> _localResults = [];
  List<FoodItem> _onlineResults = [];
  bool _searchingOnline = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    _debounce?.cancel();
    final q = _controller.text;
    setState(() {
      _query = q;
      _hasSearched = q.trim().isNotEmpty;
      _onlineResults = [];
    });
    if (q.trim().isEmpty) {
      setState(() => _localResults = []);
      return;
    }
    // Instant local search (no debounce)
    final repo = ref.read(foodSearchRepositoryProvider);
    setState(() => _localResults = repo.searchLocal(q));
    // Debounced online search
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchOnline(q));
  }

  Future<void> _searchOnline(String q) async {
    if (q.trim().length < 3) return;
    setState(() => _searchingOnline = true);
    final repo = ref.read(foodSearchRepositoryProvider);
    final results = await repo.searchOnline(q, limit: 10);
    if (!mounted) return;
    setState(() {
      _onlineResults = results;
      _searchingOnline = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectFood(FoodItem item) {
    HapticFeedback.selectionClick();
    // Go to portion editor before saving
    context.push('/manual/portion', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResults = _localResults.isNotEmpty || _onlineResults.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add food'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search food… (e.g. chicken rice)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: theme.textTheme.bodyLarge,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 18),
                      color: AppColors.textTertiary,
                      onPressed: () {
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),

          // Barcode entry shortcut
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Material(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/barcode'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: AppColors.brand, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan barcode',
                          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.brand),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: AppColors.brand, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: !_hasSearched
                ? _EmptySearchState()
                : !hasResults && !_searchingOnline
                    ? _NoResultsState(query: _query)
                    : _ResultsList(
                        local: _localResults,
                        online: _onlineResults,
                        searchingOnline: _searchingOnline,
                        onTap: _selectFood,
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = [
      ('🍚', 'White rice'),
      ('🍗', 'Chicken breast'),
      ('🥚', 'Eggs'),
      ('🍝', 'Pasta'),
      ('🍜', 'Noodles'),
      ('🥗', 'Salad'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick picks',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return _SuggestionChip(emoji: s.$1, label: s.$2);
            }).toList(),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Text('🔎', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Search 200+ common foods',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Or scan a barcode for packaged products',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Trigger search via the controller of the parent
          final state = context.findAncestorStateOfType<_FoodSearchScreenState>();
          state?._controller.text = label;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤷', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or scan the barcode',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.local,
    required this.online,
    required this.searchingOnline,
    required this.onTap,
  });
  final List<FoodItem> local;
  final List<FoodItem> online;
  final bool searchingOnline;
  final ValueChanged<FoodItem> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (local.isNotEmpty) ...[
          Text(
            'LOCAL',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          ...local.asMap().entries.map((e) => _FoodResultTile(
                item: e.value,
                index: e.key,
                onTap: () => onTap(e.value),
              )),
        ],
        if (online.isNotEmpty || searchingOnline) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'OPEN FOOD FACTS',
                style: theme.textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
              if (searchingOnline) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...online.asMap().entries.map((e) => _FoodResultTile(
                item: e.value,
                index: e.key + local.length,
                onTap: () => onTap(e.value),
              )),
        ],
      ],
    );
  }
}

class _FoodResultTile extends StatelessWidget {
  const _FoodResultTile({
    required this.item,
    required this.index,
    required this.onTap,
  });
  final FoodItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(item.categoryEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.caloriesPer100g.round()} kcal · '
                        'P ${item.protein.toStringAsFixed(0)} · '
                        'C ${item.carbs.toStringAsFixed(0)} · '
                        'F ${item.fat.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'per 100g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add, color: AppColors.brand, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 30 * index),
          duration: AppMotion.fast,
        ).slideX(begin: 0.05, end: 0);
  }
}