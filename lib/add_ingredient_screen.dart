import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'ingredient_repository.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';

class AddIngredientScreen extends StatefulWidget {
  final IngredientRepository? repository;

  const AddIngredientScreen({super.key, this.repository});

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryController = TextEditingController();
  DateTime? _selectedExpiry;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = AuthService.instance.getCurrentUserIdSync();

    // expiry stored in ISO yyyy-MM-dd; if user picked a date, use that
    String? expiryIso;
    if (_selectedExpiry != null) {
      expiryIso = DateFormat('yyyy-MM-dd').format(_selectedExpiry!);
    } else if (_expiryController.text.trim().isNotEmpty) {
      // backwards-compatible parsing of manually entered legacy values
      try {
        final parsed = DateFormat(
          'dd/MM/yyyy',
        ).parseStrict(_expiryController.text.trim());
        expiryIso = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        try {
          final parsed = DateTime.parse(_expiryController.text.trim());
          expiryIso = DateFormat('yyyy-MM-dd').format(parsed);
        } catch (_) {
          expiryIso = _expiryController.text.trim();
        }
      }
    }

    final values = {
      'name': _nameController.text.trim(),
      'quantity': _quantityController.text.trim(),
      'expiryDate': expiryIso,
      'note': _noteController.text.trim(),
      'userId': currentUserId,
    };

    final repo = widget.repository ?? DatabaseHelper.instance;
    await repo.insertIngredient(values);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Ingredient',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: InputBorder.none,
                              hintText: 'Ginger root',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F1F1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: InputBorder.none,
                              hintText: '500 gram',
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F1F1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedExpiry ?? now,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 10),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedExpiry = picked;
                                  _expiryController.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(picked);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _expiryController,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date',
                                  border: InputBorder.none,
                                  hintText: 'dd/MM/yyyy',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F1F1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                          child: TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: InputBorder.none,
                              hintText: '1 plastic bag',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveIngredient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
