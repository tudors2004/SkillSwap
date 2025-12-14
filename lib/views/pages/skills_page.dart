import 'package:flutter/material.dart';
import 'package:skillswap/services/skills_service.dart';
import 'package:easy_localization/easy_localization.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  final SkillsService _skillsService = SkillsService();
  bool _isLoading = true;
  Map<String, dynamic>? _skillsData;
  bool _isEditing = false;

  final _skillsToOfferControllers = <_SkillInputControllers>[];
  final _skillsToLearnControllers = <_SkillInputControllers>[];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    for (var controller in _skillsToOfferControllers) {
      controller.dispose();
    }
    for (var controller in _skillsToLearnControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSkills() async {
    try {
      final data = await _skillsService.getSkills();
      if (mounted) {
        setState(() {
          _skillsData = data;
          if (data != null) {
            _initializeControllersFromData(data);
            _isEditing = false;
          } else {
            _isEditing = false; 
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('skills_page.error_loading_skills'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  void _initializeControllersFromData(Map<String, dynamic> data) {
    final skillsToOffer = (data['skillsToOffer'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final skillsToLearn = (data['skillsToLearn'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    _skillsToOfferControllers.clear();
    for (var skill in skillsToOffer) {
      _skillsToOfferControllers.add(_SkillInputControllers(
        skill['name'] ?? '',
        skill['description'] ?? '',
      ));
    }

    _skillsToLearnControllers.clear();
    for (var skill in skillsToLearn) {
      _skillsToLearnControllers.add(_SkillInputControllers(
        skill['name'] ?? '',
        skill['description'] ?? '',
      ));
    }
  }

  void _addNewSkillToOffer({bool isFirstTime = false}) {
    if (!isFirstTime && _skillsToOfferControllers.any((c) => c.nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('skills_page.fill_existing_skill'.tr())),
      );
      return;
    }
    setState(() {
      _skillsToOfferControllers.add(_SkillInputControllers());
    });
  }

  void _addNewSkillToLearn({bool isFirstTime = false}) {
    if (!isFirstTime && _skillsToLearnControllers.any((c) => c.nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('skills_page.fill_existing_skill'.tr())),
      );
      return;
    }
    setState(() {
      _skillsToLearnControllers.add(_SkillInputControllers());
    });
  }

  void _removeSkillToOffer(int index) {
    setState(() {
      _skillsToOfferControllers[index].dispose();
      _skillsToOfferControllers.removeAt(index);
    });
  }

  void _removeSkillToLearn(int index) {
    setState(() {
      _skillsToLearnControllers[index].dispose();
      _skillsToLearnControllers.removeAt(index);
    });
  }

  Future<void> _saveSkills() async {
    final skillsToOffer = _skillsToOfferControllers
        .map((c) => {'name': c.nameController.text, 'description': c.descriptionController.text})
        .where((skill) => (skill['name'] as String).isNotEmpty)
        .toList();

    final skillsToLearn = _skillsToLearnControllers
        .map((c) => {'name': c.nameController.text, 'description': ''})
        .where((skill) => (skill['name'] as String).isNotEmpty)
        .toList();
    
    if (skillsToOffer.isEmpty && skillsToLearn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('skills_page.add_at_least_one_skill'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _skillsService.saveSkills({
        'skillsToOffer': skillsToOffer,
        'skillsToLearn': skillsToLearn,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('skills_page.skills_saved_success'.tr())),
        );
        await _loadSkills();
        setState(() {
          _isEditing = false;
        });
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('skills_page.error_saving_skills'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isEditing) {
      return _buildEditingView();
    }

    if (_skillsData == null) {
      return _buildInitialSetupView();
    }

    return _buildSkillsView();
  }

  Widget _buildEditingView() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'skills_page.title_edit'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildEditSkillsCard(
                  'skills_page.skills_to_offer'.tr(),
                  _skillsToOfferControllers,
                  _addNewSkillToOffer,
                  _removeSkillToOffer,
                  Colors.orange,
                  Icons.volunteer_activism,
                  showDescription: true,
                ),
                const SizedBox(height: 16),
                _buildEditSkillsCard(
                  'skills_page.skills_to_learn'.tr(),
                  _skillsToLearnControllers,
                  _addNewSkillToLearn,
                  _removeSkillToLearn,
                  Colors.blue,
                  Icons.school,
                  showDescription: false,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(25),
                        child: InkWell(
                          onTap: () {
                            if (_skillsData != null) {
                              _initializeControllersFromData(_skillsData!);
                            }
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Material(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                        elevation: 4,
                        shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                        child: InkWell(
                          onTap: _saveSkills,
                          borderRadius: BorderRadius.circular(25),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'skills_page.save_skills'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSkillsCard(
    String title,
    List<_SkillInputControllers> controllers,
    VoidCallback addSkill,
    Function(int) removeSkill,
    Color accentColor,
    IconData icon,
    {required bool showDescription}
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...List.generate(controllers.length, (index) {
              return _buildSkillInput(controllers[index], () => removeSkill(index), accentColor, showDescription: showDescription);
            }),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: addSkill,
                icon: Icon(Icons.add_circle_outline, color: accentColor),
                label: Text(
                  'skills_page.add_skill'.tr(),
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillInput(_SkillInputControllers controller, VoidCallback onRemove, Color accentColor, {required bool showDescription}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'skills_page.skill_name'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                onPressed: onRemove,
              ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'skills_page.description'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsView() {
    final theme = Theme.of(context);
    final skillsToOffer = (_skillsData!['skillsToOffer'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final skillsToLearn = (_skillsData!['skillsToLearn'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalSkills = skillsToOffer.length + skillsToLearn.length;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'skills_page.title_view'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalSkills ${totalSkills == 1 ? 'skill' : 'skills'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Edit Button
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 20, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'skills_page.edit_skills'.tr(),
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildDisplayCard(
                  'skills_page.skills_to_offer'.tr(),
                  skillsToOffer,
                  Colors.orange,
                  Icons.volunteer_activism,
                  showDescription: true,
                ),
                const SizedBox(height: 16),
                _buildDisplayCard(
                  'skills_page.skills_to_learn'.tr(),
                  skillsToLearn,
                  Colors.blue,
                  Icons.school,
                  showDescription: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayCard(
    String title,
    List<Map<String, dynamic>> skills,
    Color accentColor,
    IconData icon,
    {required bool showDescription}
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${skills.length}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'skills_page.no_skills_added_section'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.15),
                          accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill['name'] ?? '',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (showDescription && skill['description'] != null && skill['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            skill['description'],
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSetupView() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'skills_page.title_view'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 60,
                    color: theme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'skills_page.no_skills_yet'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Material(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  elevation: 4,
                  shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                        if (_skillsToOfferControllers.isEmpty) {
                          _skillsToOfferControllers.add(_SkillInputControllers());
                        }
                        if (_skillsToLearnControllers.isEmpty) {
                          _skillsToLearnControllers.add(_SkillInputControllers());
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'skills_page.add_your_skills'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillInputControllers {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  _SkillInputControllers([String name = '', String description = ''])
      : nameController = TextEditingController(text: name),
        descriptionController = TextEditingController(text: description);

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}
