import 'package:flutter/material.dart';
import 'package:skillswap/services/skills_service.dart';

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
            _addNewSkillToOffer(isFirstTime: true);
            _addNewSkillToLearn(isFirstTime: true);
            _isEditing = true;
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
          SnackBar(content: Text('An error occurred while loading skills: $e')),
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
        const SnackBar(content: Text('Please fill in the existing skill before adding a new one.')),
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
        const SnackBar(content: Text('Please fill in the existing skill before adding a new one.')),
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
        const SnackBar(content: Text('Please add at least one skill.')),
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
          const SnackBar(content: Text('Skills saved successfully!')),
        );
        await _loadSkills();
        setState(() {
          _isEditing = false;
        });
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving skills: $e')),
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditingView()
              : _skillsData != null
                  ? _buildSkillsView()
                  : _buildInitialSetupView(),
    );
  }

  Widget _buildEditingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkillsSection(
            'Skills I Can Offer',
            _skillsToOfferControllers,
            _addNewSkillToOffer,
            _removeSkillToOffer,
            showDescription: true,
          ),
          const SizedBox(height: 24),
          _buildSkillsSection(
            'Skills I Want to Learn',
            _skillsToLearnControllers,
            _addNewSkillToLearn,
            _removeSkillToLearn,
            showDescription: false,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: _saveSkills,
              child: const Text('Save Skills'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
    String title,
    List<_SkillInputControllers> controllers,
    VoidCallback addSkill,
    Function(int) removeSkill,
    {required bool showDescription}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(controllers.length, (index) {
          return _buildSkillInput(controllers[index], () => removeSkill(index), showDescription: showDescription);
        }),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: addSkill,
          icon: const Icon(Icons.add),
          label: const Text('Add Skill'),
        ),
      ],
    );
  }

  Widget _buildSkillInput(_SkillInputControllers controller, VoidCallback onRemove, {required bool showDescription}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                border: OutlineInputBorder(),
              ),
            ),
            if(showDescription)
            const SizedBox(height: 12),
            if(showDescription)
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsView() {
    final skillsToOffer = (_skillsData!['skillsToOffer'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final skillsToLearn = (_skillsData!['skillsToLearn'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDisplaySection('Skills I Can Offer', skillsToOffer, showDescription: true),
                  const SizedBox(height: 24),
                  _buildDisplaySection('Skills I Want to Learn', skillsToLearn, showDescription: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: const Text('Edit Skills'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection(String title, List<Map<String, dynamic>> skills, {required bool showDescription}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          const Text('No skills added yet.')
        else
          ...skills.map((skill) => _buildSkillDisplay(skill['name'] ?? '', showDescription ? skill['description'] ?? '' : null)),
      ],
    );
  }

  Widget _buildSkillDisplay(String name, String? description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: description != null && description.isNotEmpty ? Text(description) : null,
      ),
    );
  }
   Widget _buildInitialSetupView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Add your skills to get started!', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: const Text('Add Skills'),
            ),
          ],
        ),
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
