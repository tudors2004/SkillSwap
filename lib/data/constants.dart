/// Language-agnostic skill categories
/// Use these internal IDs for filtering and storage
/// Use `category.localizationKey` for UI display
enum SkillCategory {
  all,
  programming,
  music,
  languages,
  sports,
  art,
  cooking,
  business,
  science,
  crafts,
  other;

  /// Get localization key for this category (for easy_localization)
  String get localizationKey => 'categories.$name';

  /// Get the internal ID string (for storage/filtering)
  String get id => name;

  /// Create from string ID
  static SkillCategory fromId(String? id) {
    if (id == null || id.isEmpty) return SkillCategory.other;
    final lowerId = id.toLowerCase();
    return SkillCategory.values.firstWhere(
      (c) => c.name == lowerId,
      orElse: () => SkillCategory.other,
    );
  }
}

class Constants {
  static const List<String> nationalities = [
    'Afghan', 'Albanian', 'Algerian', 'American', 'Andorran', 'Angolan',
    'Argentine', 'Armenian', 'Australian', 'Austrian', 'Azerbaijani',
    'Bahamian', 'Bahraini', 'Bangladeshi', 'Barbadian', 'Belarusian',
    'Belgian', 'Belizean', 'Beninese', 'Bhutanese', 'Bolivian',
    'Bosnian', 'Brazilian', 'British', 'Bruneian', 'Bulgarian',
    'Burkinabe', 'Burmese', 'Burundian', 'Cambodian', 'Cameroonian',
    'Canadian', 'Cape Verdean', 'Central African', 'Chadian', 'Chilean',
    'Chinese', 'Colombian', 'Comoran', 'Congolese', 'Costa Rican',
    'Croatian', 'Cuban', 'Cypriot', 'Czech', 'Danish', 'Djiboutian',
    'Dominican', 'Dutch', 'Ecuadorian', 'Egyptian', 'Emirati',
    'English', 'Equatorial Guinean', 'Eritrean', 'Estonian', 'Ethiopian',
    'Fijian', 'Filipino', 'Finnish', 'French', 'Gabonese', 'Gambian',
    'Georgian', 'German', 'Ghanaian', 'Greek', 'Grenadian',
    'Guatemalan', 'Guinean', 'Guyanese', 'Haitian', 'Honduran',
    'Hungarian', 'Icelandic', 'Indian', 'Indonesian', 'Iranian',
    'Iraqi', 'Irish', 'Israeli', 'Italian', 'Ivorian', 'Jamaican',
    'Japanese', 'Jordanian', 'Kazakhstani', 'Kenyan', 'Kuwaiti',
    'Kyrgyz', 'Laotian', 'Latvian', 'Lebanese', 'Liberian', 'Libyan',
    'Liechtensteiner', 'Lithuanian', 'Luxembourger', 'Macedonian',
    'Malagasy', 'Malawian', 'Malaysian', 'Maldivian', 'Malian',
    'Maltese', 'Marshallese', 'Mauritanian', 'Mauritian', 'Mexican',
    'Micronesian', 'Moldovan', 'Monacan', 'Mongolian', 'Montenegrin',
    'Moroccan', 'Mozambican', 'Namibian', 'Nauruan', 'Nepalese',
    'New Zealander', 'Nicaraguan', 'Nigerien', 'Nigerian', 'Norwegian',
    'Omani', 'Pakistani', 'Palauan', 'Palestinian', 'Panamanian',
    'Papua New Guinean', 'Paraguayan', 'Peruvian', 'Polish', 'Portuguese',
    'Qatari', 'Romanian', 'Russian', 'Rwandan', 'Saint Lucian',
    'Salvadoran', 'Samoan', 'San Marinese', 'Sao Tomean', 'Saudi',
    'Scottish', 'Senegalese', 'Serbian', 'Seychellois', 'Sierra Leonean',
    'Singaporean', 'Slovak', 'Slovenian', 'Solomon Islander', 'Somali',
    'South African', 'South Korean', 'Spanish', 'Sri Lankan', 'Sudanese',
    'Surinamer', 'Swazi', 'Swedish', 'Swiss', 'Syrian', 'Taiwanese',
    'Tajik', 'Tanzanian', 'Thai', 'Togolese', 'Tongan',
    'Trinidadian', 'Tunisian', 'Turkish', 'Tuvaluan', 'Ugandan',
    'Ukrainian', 'Uruguayan', 'Uzbek', 'Venezuelan', 'Vietnamese',
    'Welsh', 'Yemenite', 'Zambian', 'Zimbabwean'
  ];

  static const List<String> kSkillCategories = [
    'all',
    'programming',
    'music',
    'languages',
    'sports',
    'art',
    'cooking',
    'business',
    'science',
    'crafts',
    'other',
  ];

  /// All skill category enums (for UI)
  static List<SkillCategory> get skillCategoryValues => SkillCategory.values;


  /// Maps keywords in ANY language to canonical category ID (lowercase)
  /// Keys should be lowercase for case-insensitive matching
  static const Map<String, String> kSkillKeywordMap = {
    // ============ PROGRAMMING ============
    // English
    'python': 'programming',
    'java': 'programming',
    'javascript': 'programming',
    'flutter': 'programming',
    'dart': 'programming',
    'react': 'programming',
    'c++': 'programming',
    'c#': 'programming',
    'html': 'programming',
    'css': 'programming',
    'coding': 'programming',
    'typescript': 'programming',
    'kotlin': 'programming',
    'swift': 'programming',
    'go': 'programming',
    'rust': 'programming',
    'ruby': 'programming',
    'php': 'programming',
    'sql': 'programming',
    'node': 'programming',
    'angular': 'programming',
    'vue': 'programming',
    'django': 'programming',
    'spring': 'programming',
    'android': 'programming',
    'ios': 'programming',
    'web development': 'programming',
    'machine learning': 'programming',
    'data science': 'programming',
    'artificial intelligence': 'programming',
    // Romanian
    'programare': 'programming',
    'dezvoltare web': 'programming',
    'inteligență artificială': 'programming',
    // French
    'programmation': 'programming',
    'développement web': 'programming',
    'développement': 'programming',
    'intelligence artificielle': 'programming',
    // Spanish
    'programación': 'programming',
    'desarrollo web': 'programming',
    'inteligencia artificial': 'programming',
    // German
    'programmierung': 'programming',
    'webentwicklung': 'programming',
    'künstliche intelligenz': 'programming',
    // Italian
    'programmazione': 'programming',
    'sviluppo web': 'programming',
    // Portuguese
    'programação': 'programming',
    'desenvolvimento web': 'programming',

    // ============ MUSIC ============
    // English
    'guitar': 'music',
    'piano': 'music',
    'violin': 'music',
    'singing': 'music',
    'voice': 'music',
    'drums': 'music',
    'music': 'music',
    'bass': 'music',
    'saxophone': 'music',
    'trumpet': 'music',
    'flute': 'music',
    'cello': 'music',
    'clarinet': 'music',
    'ukulele': 'music',
    'harmonica': 'music',
    'keyboard': 'music',
    'music theory': 'music',
    'composition': 'music',
    'dj': 'music',
    'music production': 'music',
    'vocal coaching': 'music',
    // Romanian
    'chitară': 'music',
    'chitara': 'music',
    'pian': 'music',
    'vioară': 'music',
    'vioara': 'music',
    'canto': 'music',
    'tobe': 'music',
    'muzică': 'music',
    'muzica': 'music',
    'saxofon': 'music',
    'trompetă': 'music',
    'flaut': 'music',
    'violoncel': 'music',
    // French
    'guitare': 'music',
    'violon': 'music',
    'chant': 'music',
    'batterie': 'music',
    'musique': 'music',
    'trompette': 'music',
    'flûte': 'music',
    'clarinette': 'music',
    'violoncelle': 'music',
    'théorie musicale': 'music',
    // Spanish
    'guitarra': 'music',
    'batería': 'music',
    'bateria': 'music',
    'cante': 'music',
    'cantar': 'music',
    'música': 'music',
    'flauta': 'music',
    'trompeta': 'music',
    // German
    'gitarre': 'music',
    'klavier': 'music',
    'geige': 'music',
    'gesang': 'music',
    'schlagzeug': 'music',
    'musik': 'music',
    'flöte': 'music',
    // Italian
    'chitarra': 'music',
    'pianoforte': 'music',
    'violino': 'music',
    'voce': 'music',
    'batteria': 'music',
    'flauto': 'music',
    'tromba': 'music',
    // Portuguese
    'violão': 'music',
    'violao': 'music',
    // Note: 'bateria' and 'música' already defined for Spanish

    // ============ SPORTS ============
    // English
    'football': 'sports',
    'soccer': 'sports',
    'tennis': 'sports',
    'climbing': 'sports',
    'yoga': 'sports',
    'gym': 'sports',
    'fitness': 'sports',
    'running': 'sports',
    'basketball': 'sports',
    'volleyball': 'sports',
    'swimming': 'sports',
    'cycling': 'sports',
    'boxing': 'sports',
    'martial arts': 'sports',
    'karate': 'sports',
    'judo': 'sports',
    'taekwondo': 'sports',
    'wrestling': 'sports',
    'golf': 'sports',
    'baseball': 'sports',
    'cricket': 'sports',
    'badminton': 'sports',
    'table tennis': 'sports',
    'skiing': 'sports',
    'snowboarding': 'sports',
    'surfing': 'sports',
    'pilates': 'sports',
    'crossfit': 'sports',
    'weightlifting': 'sports',
    'hiking': 'sports',
    // Romanian
    'fotbal': 'sports',
    'tenis': 'sports',
    'alpinism': 'sports',
    'sală': 'sports',
    'sala': 'sports',
    'alergare': 'sports',
    'baschet': 'sports',
    'volei': 'sports',
    'înot': 'sports',
    'inot': 'sports',
    'ciclism': 'sports',
    'box': 'sports',
    'arte marțiale': 'sports',
    'drumeții': 'sports',
    // French
    'natation': 'sports',
    'cyclisme': 'sports',
    'boxe': 'sports',
    'arts martiaux': 'sports',
    'escalade': 'sports',
    'course': 'sports',
    'musculation': 'sports',
    'randonnée': 'sports',
    // Spanish
    'fútbol': 'sports',
    'futbol': 'sports',
    'natación': 'sports',
    'ciclismo': 'sports',
    'artes marciales': 'sports',
    'senderismo': 'sports',
    // German
    'fußball': 'sports',
    'fussball': 'sports',
    'schwimmen': 'sports',
    'radfahren': 'sports',
    'boxen': 'sports',
    'kampfsport': 'sports',
    'wandern': 'sports',
    // Italian
    'calcio': 'sports',
    'nuoto': 'sports',
    // Note: 'ciclismo' already defined for Spanish
    'pugilato': 'sports',
    'arti marziali': 'sports',
    // Portuguese
    'futebol': 'sports',
    'natação': 'sports',
    'artes marciais': 'sports',
    'caminhada': 'sports',

    // ============ LANGUAGES ============
    // English
    'english': 'languages',
    'spanish': 'languages',
    'german': 'languages',
    'french': 'languages',
    'romanian': 'languages',
    'italian': 'languages',
    'portuguese': 'languages',
    'russian': 'languages',
    'chinese': 'languages',
    'mandarin': 'languages',
    'japanese': 'languages',
    'korean': 'languages',
    'arabic': 'languages',
    'hindi': 'languages',
    'dutch': 'languages',
    'swedish': 'languages',
    'polish': 'languages',
    'turkish': 'languages',
    'greek': 'languages',
    'hebrew': 'languages',
    'thai': 'languages',
    'vietnamese': 'languages',
    // Romanian
    'engleză': 'languages',
    'engleza': 'languages',
    'spaniolă': 'languages',
    'spaniola': 'languages',
    'germană': 'languages',
    'germana': 'languages',
    'franceză': 'languages',
    'franceza': 'languages',
    'română': 'languages',
    'romana': 'languages',
    'italiană': 'languages',
    'italiana': 'languages',
    'portugheză': 'languages',
    'portugheza': 'languages',
    'rusă': 'languages',
    'rusa': 'languages',
    'chineză': 'languages',
    'chineza': 'languages',
    'japoneză': 'languages',
    'japoneza': 'languages',
    'coreeană': 'languages',
    'coreana': 'languages',
    'arabă': 'languages',
    'araba': 'languages',
    // French
    'anglais': 'languages',
    'espagnol': 'languages',
    'allemand': 'languages',
    'français': 'languages',
    'roumain': 'languages',
    'italien': 'languages',
    'portugais': 'languages',
    'russe': 'languages',
    'chinois': 'languages',
    'japonais': 'languages',
    'coréen': 'languages',
    'arabe': 'languages',
    // Spanish
    'inglés': 'languages',
    'español': 'languages',
    'alemán': 'languages',
    'francés': 'languages',
    'rumano': 'languages',
    'ruso': 'languages',
    'chino': 'languages',
    'japonés': 'languages',
    'coreano': 'languages',
    'árabe': 'languages',
    // German
    'englisch': 'languages',
    'spanisch': 'languages',
    'deutsch': 'languages',
    'französisch': 'languages',
    'rumänisch': 'languages',
    'italienisch': 'languages',
    'portugiesisch': 'languages',
    'russisch': 'languages',
    'chinesisch': 'languages',
    'japanisch': 'languages',
    'koreanisch': 'languages',
    'arabisch': 'languages',
    // Italian
    'inglese': 'languages',
    'spagnolo': 'languages',
    'tedesco': 'languages',
    'francese': 'languages',
    'rumeno': 'languages',
    'portoghese': 'languages',
    'cinese': 'languages',
    'giapponese': 'languages',

    // ============ COOKING ============
    // English
    'cooking': 'cooking',
    'baking': 'cooking',
    'chef': 'cooking',
    'pastry': 'cooking',
    'grilling': 'cooking',
    'bbq': 'cooking',
    'vegan cooking': 'cooking',
    'italian cuisine': 'cooking',
    'french cuisine': 'cooking',
    'asian cuisine': 'cooking',
    'desserts': 'cooking',
    'bread making': 'cooking',
    'cake decorating': 'cooking',
    'wine pairing': 'cooking',
    'cocktails': 'cooking',
    'barista': 'cooking',
    // Romanian
    'gătit': 'cooking',
    'gatit': 'cooking',
    'bucătărie': 'cooking',
    'bucatarie': 'cooking',
    'patiserie': 'cooking',
    'copt': 'cooking',
    'deserturi': 'cooking',
    'prăjituri': 'cooking',
    'prajituri': 'cooking',
    // French
    'cuisine': 'cooking',
    'cuisson': 'cooking',
    'pâtisserie': 'cooking',
    'patisserie': 'cooking',
    'boulangerie': 'cooking',
    'gâteaux': 'cooking',
    'gateaux': 'cooking',
    // Spanish
    'cocina': 'cooking',
    'cocinar': 'cooking',
    'hornear': 'cooking',
    'pastelería': 'cooking',
    'postres': 'cooking',
    // German
    'kochen': 'cooking',
    'backen': 'cooking',
    'küche': 'cooking',
    'konditorei': 'cooking',
    // Italian
    'cucina': 'cooking',
    'cucinare': 'cooking',
    'pasticceria': 'cooking',
    'dolci': 'cooking',
    // Portuguese
    'cozinha': 'cooking',
    'cozinhar': 'cooking',
    'confeitaria': 'cooking',
    'sobremesas': 'cooking',

    // ============ ART ============
    // English
    'painting': 'art',
    'drawing': 'art',
    'design': 'art',
    'photography': 'art',
    'graphic design': 'art',
    'illustration': 'art',
    'sketching': 'art',
    'watercolor': 'art',
    'oil painting': 'art',
    'sculpture': 'art',
    'pottery': 'art',
    'ceramics': 'art',
    'digital art': 'art',
    '3d modeling': 'art',
    'animation': 'art',
    'video editing': 'art',
    'ui design': 'art',
    'ux design': 'art',
    'calligraphy': 'art',
    'fashion design': 'art',
    'interior design': 'art',
    'architecture': 'art',
    // Romanian
    'pictură': 'art',
    'pictura': 'art',
    'desen': 'art',
    'fotografie': 'art',
    'sculptură': 'art',
    'sculptura': 'art',
    'ceramică': 'art',
    'ceramica': 'art',
    'animație': 'art',
    'animatie': 'art',
    'caligrafie': 'art',
    'arhitectură': 'art',
    'arhitectura': 'art',
    // French
    'peinture': 'art',
    'dessin': 'art',
    'photographie': 'art',
    'aquarelle': 'art',
    'céramique': 'art',
    'calligraphie': 'art',
    // Spanish
    'pintura': 'art',
    'dibujo': 'art',
    'fotografía': 'art',
    'escultura': 'art',
    'cerámica': 'art',
    'caligrafía': 'art',
    'arquitectura': 'art',
    // German
    'malerei': 'art',
    'zeichnung': 'art',
    // Note: 'fotografie' already defined for Romanian
    'bildhauerei': 'art',
    'keramik': 'art',
    'kalligraphie': 'art',
    'architektur': 'art',
    // Italian
    'pittura': 'art',
    'disegno': 'art',
    'fotografia': 'art',
    'scultura': 'art',
    // Portuguese (pintura, escultura already defined in Spanish)
    'desenho': 'art',
    'cerâmica': 'art',

    // ============ BUSINESS ============
    // English
    'marketing': 'business',
    'sales': 'business',
    'accounting': 'business',
    'finance': 'business',
    'investing': 'business',
    'entrepreneurship': 'business',
    'leadership': 'business',
    'public speaking': 'business',
    'negotiation': 'business',
    'project management': 'business',
    'copywriting': 'business',
    'seo': 'business',
    'social media': 'business',
    'excel': 'business',
    'data analysis': 'business',
    'consulting': 'business',
    'real estate': 'business',
    'e-commerce': 'business',
    'branding': 'business',
    // Romanian
    'vânzări': 'business',
    'vanzari': 'business',
    'contabilitate': 'business',
    'finanțe': 'business',
    'finante': 'business',
    'investiții': 'business',
    'investitii': 'business',
    'antreprenoriat': 'business',
    'management': 'business',
    'negociere': 'business',
    'imobiliare': 'business',
    // French
    'ventes': 'business',
    'comptabilité': 'business',
    'comptabilite': 'business',
    'investissement': 'business',
    'entreprenariat': 'business',
    'gestion de projet': 'business',
    'immobilier': 'business',
    // Spanish
    'ventas': 'business',
    'contabilidad': 'business',
    'finanzas': 'business',
    'inversión': 'business',
    'emprendimiento': 'business',
    'gestión de proyectos': 'business',
    'inmobiliaria': 'business',
    // German
    'verkauf': 'business',
    'buchhaltung': 'business',
    'finanzen': 'business',
    'investition': 'business',
    'unternehmertum': 'business',
    'projektmanagement': 'business',
    'immobilien': 'business',
    // Italian
    'vendite': 'business',
    'contabilità': 'business',
    'finanza': 'business',
    'investimento': 'business',
    'imprenditorialità': 'business',

    // ============ SCIENCE ============
    // English
    'mathematics': 'science',
    'physics': 'science',
    'chemistry': 'science',
    'biology': 'science',
    'astronomy': 'science',
    'statistics': 'science',
    'calculus': 'science',
    'algebra': 'science',
    'geometry': 'science',
    'psychology': 'science',
    'electronics': 'science',
    'robotics': 'science',
    'engineering': 'science',
    'medicine': 'science',
    'anatomy': 'science',
    'environmental science': 'science',
    // Romanian
    'matematică': 'science',
    'matematica': 'science',
    'fizică': 'science',
    'fizica': 'science',
    'chimie': 'science',
    'biologie': 'science',
    'astronomie': 'science',
    'statistică': 'science',
    'statistica': 'science',
    'psihologie': 'science',
    'electronică': 'science',
    'electronica': 'science',
    'robotică': 'science',
    'robotica': 'science',
    'inginerie': 'science',
    'medicină': 'science',
    'medicina': 'science',
    // French (chimie, biologie, astronomie already defined for Romanian)
    'mathématiques': 'science',
    'mathematiques': 'science',
    'physique': 'science',
    'psychologie': 'science',
    'électronique': 'science',
    'electronique': 'science',
    'robotique': 'science',
    'ingénierie': 'science',
    'médecine': 'science',
    // Spanish
    'matemáticas': 'science',
    'física': 'science',
    'química': 'science',
    'biología': 'science',
    'astronomía': 'science',
    'psicología': 'science',
    'electrónica': 'science',
    'robótica': 'science',
    'ingeniería': 'science',
    // Note: 'medicina' already defined for Romanian
    // German (biologie, astronomie, psychologie already defined)
    'mathematik': 'science',
    'physik': 'science',
    'chemie': 'science',
    'elektronik': 'science',
    'robotik': 'science',
    'ingenieurwesen': 'science',
    'medizin': 'science',
    // Italian (matematica conflicts with Romanian)
    'fisica': 'science',
    'chimica': 'science',
    'astronomia': 'science',
    'psicologia': 'science',
    'elettronica': 'science',
    'ingegneria': 'science',

    // ============ CRAFTS ============
    // English
    'knitting': 'crafts',
    'sewing': 'crafts',
    'crocheting': 'crafts',
    'embroidery': 'crafts',
    'woodworking': 'crafts',
    'jewelry making': 'crafts',
    'origami': 'crafts',
    'leatherwork': 'crafts',
    'candle making': 'crafts',
    'soap making': 'crafts',
    'quilting': 'crafts',
    'macrame': 'crafts',
    'scrapbooking': 'crafts',
    'card making': 'crafts',
    'beading': 'crafts',
    'weaving': 'crafts',
    // Romanian
    'tricotat': 'crafts',
    'cusut': 'crafts',
    'croșetat': 'crafts',
    'crosetat': 'crafts',
    'broderie': 'crafts',
    'tâmplărie': 'crafts',
    'tamplarie': 'crafts',
    'bijuterii': 'crafts',
    'lumânări': 'crafts',
    'lumanari': 'crafts',
    'săpun': 'crafts',
    'sapun': 'crafts',
    // French (broderie already defined in Romanian)
    'tricot': 'crafts',
    'couture': 'crafts',
    'crochet': 'crafts',
    'menuiserie': 'crafts',
    'bijouterie': 'crafts',
    'bougies': 'crafts',
    'savon': 'crafts',
    'tissage': 'crafts',
    // Spanish
    'tejido': 'crafts',
    'costura': 'crafts',
    'ganchillo': 'crafts',
    'bordado': 'crafts',
    'carpintería': 'crafts',
    'joyería': 'crafts',
    'velas': 'crafts',
    'jabón': 'crafts',
    // German
    'stricken': 'crafts',
    'nähen': 'crafts',
    'häkeln': 'crafts',
    'stickerei': 'crafts',
    'holzarbeit': 'crafts',
    'schmuckherstellung': 'crafts',
    'kerzenherstellung': 'crafts',
    'seifenherstellung': 'crafts',
    // Italian
    'maglia': 'crafts',
    'cucito': 'crafts',
    'uncinetto': 'crafts',
    'ricamo': 'crafts',
    'falegnameria': 'crafts',
    'gioielleria': 'crafts',
    'candele': 'crafts',
  };


  /// Detects a single category from skill name (returns lowercase category ID)
  static String detectCategory(String skillName) {
    if (skillName.isEmpty) return 'other';

    final lowerValue = skillName.trim().toLowerCase();

    var sortedKeys = kSkillKeywordMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in sortedKeys) {
      if (lowerValue.contains(key.toLowerCase())) {
        return kSkillKeywordMap[key]!;
      }
    }
    return 'other';
  }

  /// Detects all matching categories from a text (description, skill name, etc.)
  /// Returns a Set of lowercase category IDs
  static Set<String> detectCategoriesFromText(String text) {
    if (text.isEmpty) return {};

    final lowerText = text.toLowerCase();
    final Set<String> categories = {};

    // Sort by length (longer matches first for accuracy)
    var sortedKeys = kSkillKeywordMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in sortedKeys) {
      if (lowerText.contains(key)) {
        categories.add(kSkillKeywordMap[key]!);
      }
    }

    return categories;
  }

  /// Check if a skill matches a category (language-agnostic)
  /// Use this for filtering users by category
  static bool skillMatchesCategory(Map<String, dynamic> skill, String categoryId) {
    if (categoryId == 'all') return true;

    // First check if skill has a stored category that matches
    final storedCategory = skill['category']?.toString().toLowerCase();
    if (storedCategory == categoryId) return true;

    // Also detect from skill name (for backward compatibility and multi-language support)
    final skillName = skill['name']?.toString() ?? '';
    final detectedCategory = detectCategory(skillName);
    return detectedCategory == categoryId;
  }

  /// Get all keywords for a specific category
  static List<String> getKeywordsForCategory(String categoryId) {
    return kSkillKeywordMap.entries
        .where((e) => e.value == categoryId)
        .map((e) => e.key)
        .toList();
  }

  static const List<Map<String, String>> phoneCountryCodes = [
    {'name': 'Afghanistan', 'code': '+93'},
    {'name': 'Albania', 'code': '+355'},
    {'name': 'Algeria', 'code': '+213'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'Argentina', 'code': '+54'},
    {'name': 'Australia', 'code': '+61'},
    {'name': 'Austria', 'code': '+43'},
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'Belgium', 'code': '+32'},
    {'name': 'Brazil', 'code': '+55'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Bulgaria', 'code': '+359'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'China', 'code': '+86'},
    {'name': 'Colombia', 'code': '+57'},
    {'name': 'Croatia', 'code': '+385'},
    {'name': 'Czech Republic', 'code': '+420'},
    {'name': 'Denmark', 'code': '+45'},
    {'name': 'Egypt', 'code': '+20'},
    {'name': 'Finland', 'code': '+358'},
    {'name': 'France', 'code': '+33'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'Greece', 'code': '+30'},
    {'name': 'Hong Kong', 'code': '+852'},
    {'name': 'Hungary', 'code': '+36'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Indonesia', 'code': '+62'},
    {'name': 'Iran', 'code': '+98'},
    {'name': 'Iraq', 'code': '+964'},
    {'name': 'Ireland', 'code': '+353'},
    {'name': 'Israel', 'code': '+972'},
    {'name': 'Italy', 'code': '+39'},
    {'name': 'Japan', 'code': '+81'},
    {'name': 'Jordan', 'code': '+962'},
    {'name': 'Kenya', 'code': '+254'},
    {'name': 'South Korea', 'code': '+82'},
    {'name': 'Kuwait', 'code': '+965'},
    {'name': 'Lebanon', 'code': '+961'},
    {'name': 'Malaysia', 'code': '+60'},
    {'name': 'Mexico', 'code': '+52'},
    {'name': 'Morocco', 'code': '+212'},
    {'name': 'Netherlands', 'code': '+31'},
    {'name': 'New Zealand', 'code': '+64'},
    {'name': 'Nigeria', 'code': '+234'},
    {'name': 'Norway', 'code': '+47'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Philippines', 'code': '+63'},
    {'name': 'Poland', 'code': '+48'},
    {'name': 'Portugal', 'code': '+351'},
    {'name': 'Qatar', 'code': '+974'},
    {'name': 'Romania', 'code': '+40'},
    {'name': 'Russia', 'code': '+7'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'Singapore', 'code': '+65'},
    {'name': 'South Africa', 'code': '+27'},
    {'name': 'Spain', 'code': '+34'},
    {'name': 'Sweden', 'code': '+46'},
    {'name': 'Switzerland', 'code': '+41'},
    {'name': 'Thailand', 'code': '+66'},
    {'name': 'Turkey', 'code': '+90'},
    {'name': 'UAE', 'code': '+971'},
    {'name': 'Ukraine', 'code': '+380'},
    {'name': 'Vietnam', 'code': '+84'},
  ];
}
