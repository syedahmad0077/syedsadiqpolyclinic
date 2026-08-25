import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/template_model.dart';
import '../models/parameter_model.dart';
import '../services/hive_database_service.dart';
import '../utils/constants.dart';

class TemplateManagerScreen extends StatefulWidget {
  const TemplateManagerScreen({super.key});

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  List<TemplateModel> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() {
      _templates = HiveDatabaseService.instance.getAllTemplates();
    });
  }

  void _openAddEditDialog([TemplateModel? template]) {
    final nameController = TextEditingController(text: template?.testName ?? '');
    final List<Map<String, TextEditingController>> paramControllers = [];

    if (template != null) {
      for (var p in template.parameters) {
        paramControllers.add({
          'name': TextEditingController(text: p.paramName),
          'range': TextEditingController(text: p.normalRange),
          'unit': TextEditingController(text: p.unit),
        });
      }
    } else {
      // Start with 1 empty parameter row
      paramControllers.add({
        'name': TextEditingController(),
        'range': TextEditingController(),
        'unit': TextEditingController(),
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(template == null ? 'Add New Test Template' : 'Edit Test Template'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Test Name (e.g. Dengue Serology, LFT)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                paramControllers.add({
                                  'name': TextEditingController(),
                                  'range': TextEditingController(),
                                  'unit': TextEditingController(),
                                });
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Parameter'),
                          ),
                        ],
                      ),
                      const Divider(),
                      ...paramControllers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final controllers = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: controllers['name'],
                                  decoration: InputDecoration(
                                    labelText: 'Param Name #${idx + 1}',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: controllers['range'],
                                  decoration: const InputDecoration(
                                    labelText: 'Normal Range',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: controllers['unit'],
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: paramControllers.length > 1
                                    ? () {
                                        setDialogState(() {
                                          paramControllers.removeAt(idx);
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryTeal),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final List<ParameterModel> params = [];
                    for (var map in paramControllers) {
                      final pName = map['name']!.text.trim();
                      final pRange = map['range']!.text.trim();
                      final pUnit = map['unit']!.text.trim();
                      if (pName.isNotEmpty) {
                        params.add(ParameterModel(
                          paramName: pName,
                          normalRange: pRange,
                          unit: pUnit,
                        ));
                      }
                    }

                    final newTemplate = TemplateModel(
                      id: template?.id ?? const Uuid().v4(),
                      testName: nameController.text.trim(),
                      parameters: params,
                    );

                    await HiveDatabaseService.instance.saveTemplate(newTemplate);
                    if (mounted) Navigator.pop(ctx);
                    _loadTemplates();
                  },
                  child: const Text('Save Template', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Test Template Manager'),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: _templates.isEmpty
          ? const Center(child: Text('No test templates configured.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final t = _templates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(t.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${t.parameters.length} Test Parameters'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openAddEditDialog(t),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await HiveDatabaseService.instance.deleteTemplate(t.id);
                            _loadTemplates();
                          },
                        ),
                      ],
                    ),
                    children: t.parameters
                        .map((p) => ListTile(
                              dense: true,
                              title: Text(p.paramName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Normal Range: ${p.normalRange} | Unit: ${p.unit}'),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: AppConstants.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
