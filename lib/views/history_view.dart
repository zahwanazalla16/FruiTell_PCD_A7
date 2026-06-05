import 'package:flutter/material.dart';
import 'dart:ui';

import '../controllers/history_controller.dart';
import '../models/history_model.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final HistoryController _controller;
  String? _selectedFruit;
  String? _selectedMaturity;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _retrySync() async {
    await _controller.retrySyncPending();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = _controller.getHistory();
    final pendingCount = _controller.getPendingCount();

    final fruits = _controller.getAvailableFruits();
    final maturities = history
        .map((e) => (e.maturity ?? 'unknown'))
        .toSet()
        .toList();
    final displayed = history.isEmpty
        ? <HistoryModel>[]
        : _controller.getHistoryFiltered(
            fruit: _selectedFruit,
            maturity: _selectedMaturity,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        const Text(
          'Scan History',
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your fresh finds and nutritional insights.',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 24),
        // Filters row
        if (history.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Fruit Dropdown
                  Expanded(
                    child: FruiTellDropdown(
                      label: 'Pilih Buah',
                      icon: Icons.local_grocery_store_rounded,
                      value: _selectedFruit,
                      items: [null, ...fruits],
                      itemLabel: (fruit) => fruit == null
                          ? 'Semua Buah'
                          : fruit[0].toUpperCase() + fruit.substring(1),
                      onChanged: (v) => setState(() => _selectedFruit = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Maturity Dropdown
                  Expanded(
                    child: FruiTellDropdown(
                      label: 'Kematangan',
                      icon: Icons.thermostat_rounded,
                      value: _selectedMaturity,
                      items: [null, ...maturities],
                      itemLabel: (m) => m == null
                          ? 'Semua Level'
                          : m[0].toUpperCase() + m.substring(1),
                      onChanged: (v) => setState(() => _selectedMaturity = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Insights panel for selected filters
              Builder(
                builder: (ctx) {
                  final insights = _controller.insightsForFilters(
                    fruit: _selectedFruit,
                    maturity: _selectedMaturity,
                  );
                  final total = insights['total'] as int? ?? 0;
                  final byFruit =
                      insights['byFruit'] as Map<String, int>? ?? {};
                  final byMaturity =
                      insights['byMaturity'] as Map<String, int>? ?? {};

                  // Only show insights if there's data
                  if (total == 0) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[200] ?? Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.blue[900],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedFruit = null;
                                  _selectedMaturity = null;
                                });
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Hasil: $total buah',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (byFruit.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Per Buah',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: byFruit.entries.map((e) {
                              return Chip(
                                label: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.blue[100],
                                side: BorderSide(
                                  color: Colors.blue[300] ?? Colors.blue,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (byMaturity.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Per Tingkat Kematangan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: byMaturity.entries.map((e) {
                              return Chip(
                                label: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.orange[100],
                                side: BorderSide(
                                  color: Colors.orange[300] ?? Colors.orange,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          ),
        // Show sync status and retry button
        if (pendingCount > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber[200] ?? Colors.amber,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.amber[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.amber[900],
                        ),
                      ),
                      Text(
                        '$pendingCount item menunggu sinkronisasi ke cloud',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
                _controller.isRetrying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber[700]!,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _retrySync,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green[200] ?? Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Text(
                  'Semua data sudah sinkron ke cloud',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (displayed.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada data scan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mulai scan di tab Scan untuk melihat history',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._buildHistoryItems(displayed),
      ],
    );
  }

  List<Widget> _buildHistoryItems(List<HistoryModel> history) {
    return history.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7E1EA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_grocery_store,
                color: Color(0xFFE93E9D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isSynced)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEB3B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: Color(0xFFF57F17),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8E6C9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 12,
                                color: Color(0xFF388E3C),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B7D4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${(item.confidence * 100).toStringAsFixed(0)}% Confidence',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(item.date),
              style: const TextStyle(
                color: Color(0xFF876F7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Kemarin';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom FruiTell Dropdown
// ─────────────────────────────────────────────────────────────────────────────

class FruiTellDropdown extends StatefulWidget {
  const FruiTellDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  State<FruiTellDropdown> createState() => _FruiTellDropdownState();
}

class _FruiTellDropdownState extends State<FruiTellDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animController;
  late Animation<double> _arrowAnim;
  late Animation<double> _fadeAnim;

  static const _pink = Color(0xFFE93E9D);
  static const _pinkLight = Color(0xFFF7E1EA);
  static const _pinkMid = Color(0xFFF5B7D4);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _animController.reverse().then((_) => _removeOverlay());
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _DropdownPanel(
                    width: size.width,
                    items: widget.items,
                    selected: widget.value,
                    itemLabel: widget.itemLabel,
                    onSelect: (v) {
                      widget.onChanged(v);
                      _closeDropdown();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.value != null;
    final displayText = widget.itemLabel(widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFE93E9D), Color(0xFFFF6DBB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF7E1EA), Color(0xFFFCF0F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOpen
                  ? _pink
                  : isActive
                      ? _pink.withOpacity(0.6)
                      : _pinkMid,
              width: _isOpen ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(_isOpen ? 0.22 : 0.08),
                blurRadius: _isOpen ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: isActive ? Colors.white : _pink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF876F7A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : const Color(0xFF3D1A2B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _arrowAnim,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: isActive ? Colors.white : _pink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Panel (overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.width,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.onSelect,
  });

  final double width;
  final List<String?> items;
  final String? selected;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onSelect;

  static const _pink = Color(0xFFE93E9D);
  static const _pinkLight = Color(0xFFF7E1EA);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pink.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: _pink.withOpacity(0.08),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              final isSelected = item == selected;
              final label = itemLabel(item);

              return InkWell(
                onTap: () => onSelect(item),
                borderRadius: BorderRadius.circular(12),
                splashColor: _pink.withOpacity(0.12),
                highlightColor: _pinkLight.withOpacity(0.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFE93E9D), Color(0xFFFF6DBB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Indicator dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : item == null
                                  ? Colors.grey.shade300
                                  : _pink.withOpacity(0.4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF3D1A2B),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
