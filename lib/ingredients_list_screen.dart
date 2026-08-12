import 'package:flutter/material.dart';
import 'add_ingredient_screen.dart';
import 'database_helper.dart';
import 'auth_service.dart';
import 'ingredient_repository.dart';

class IngredientsListScreen extends StatefulWidget {
  final IngredientRepository? repository;

  const IngredientsListScreen({super.key, this.repository});

  @override
  State<IngredientsListScreen> createState() => _IngredientsListScreenState();
}

class _IngredientsListScreenState extends State<IngredientsListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final Set<int> _selectedIds = {};
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = AuthService.instance.getCurrentUserIdSync();
      final repo = widget.repository ?? DatabaseHelper.instance;
      final rows = await repo.getIngredients(currentUserId);
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load ingredients.\nPlease try again.';
        _loading = false;
      });
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    // Try ISO parse first
    try {
      return DateTime.parse(s);
    } catch (_) {}

    // Try dd/MM/yyyy
    final parts = s.split(RegExp(r'[^0-9]'))..removeWhere((p) => p.isEmpty);
    if (parts.length >= 3) {
      try {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      } catch (_) {}
    }

    return null;
  }

  bool _isExpiringSoon(DateTime expirationDate) {
    final today = DateTime.now();
    final expDate = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    final justToday = DateTime(today.year, today.month, today.day);
    final diff = expDate.difference(justToday).inDays;
    return diff < 3; // less than 3 days -> red
  }

  String _expiryText(DateTime expirationDate) {
    final today = DateTime.now();
    final expDate = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    final justToday = DateTime(today.year, today.month, today.day);
    final diff = expDate.difference(justToday).inDays;

    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  void _toggleSelection(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items selected')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ingredients?'),
        content: const Text(
          'Are you sure you want to delete the selected ingredients?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      final currentUserId = AuthService.instance.getCurrentUserIdSync();
      final repo = widget.repository ?? DatabaseHelper.instance;
      for (final id in _selectedIds.toList()) {
        await repo.deleteIngredient(id, currentUserId);
      }
      _selectedIds.clear();
      await _loadItems();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Delete failed')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openAdd() async {
    final res = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddIngredientScreen()));
    if (res == true) {
      await _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pantry', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _deleting ? null : _confirmAndDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
          ),
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, color: Colors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
          child: Builder(
            builder: (context) {
              if (_loading) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading...'),
                    ],
                  ),
                );
              }

              if (_error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                );
              }

              if (_items.isEmpty) {
                return const Center(child: Text('No items found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, thickness: 1),
                itemBuilder: (context, index) {
                  final row = _items[index];
                  final id = (row['id'] as int);
                  final name = row['name'] as String? ?? '';
                  final quantity = row['quantity'] as String?;
                  final expiryRaw = row['expiryDate'] as String?;
                  final expiryDate = _parseDate(expiryRaw);
                  final expiryText = expiryDate != null
                      ? _expiryText(expiryDate)
                      : '';
                  final expiringSoon = expiryDate != null
                      ? _isExpiringSoon(expiryDate)
                      : false;

                  Color expiryColor = Colors.black54;
                  if (expiryDate != null) {
                    final today = DateTime.now();
                    final expDate = DateTime(
                      expiryDate.year,
                      expiryDate.month,
                      expiryDate.day,
                    );
                    if (expDate.isBefore(
                      DateTime(today.year, today.month, today.day),
                    )) {
                      expiryColor = Colors.red;
                    } else if (expiringSoon) {
                      expiryColor = Colors.red;
                    } else {
                      expiryColor = Colors.green.shade700;
                    }
                  }

                  return ListTile(
                    leading: Checkbox(
                      value: _selectedIds.contains(id),
                      onChanged: (v) => _toggleSelection(id, v == true),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quantity != null && quantity.isNotEmpty)
                          Text(
                            'Quantity: $quantity',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        if (expiryText.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                'Expiry: ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                expiryText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: expiryColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
