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
  'All',
  'Programming',
  'Music',
  'Languages',
  'Sports',
  'Art',
  'Cooking',
  'Other',
  ];


  static const Map<String, String> kSkillKeywordMap = {
  // Programming
  'python': 'Programming',
  'java': 'Programming',
  'javascript': 'Programming',
  'flutter': 'Programming',
  'dart': 'Programming',
  'react': 'Programming',
  'c++': 'Programming',
  'c#': 'Programming',
  'html': 'Programming',
  'css': 'Programming',
  'coding': 'Programming',
  
  // Music
  'guitar': 'Music',
  'piano': 'Music',
  'violin': 'Music',
  'singing': 'Music',
  'voice': 'Music',
  'drums': 'Music',
  'music': 'Music',
  
  // Sports
  'football': 'Sports',
  'soccer': 'Sports',
  'tennis': 'Sports',
  'climbing': 'Sports',
  'yoga': 'Sports',
  'gym': 'Sports',
  'fitness': 'Sports',
  'running': 'Sports',

  // Languages
  'english': 'Languages',
  'spanish': 'Languages',
  'german': 'Languages',
  'french': 'Languages',
  'romanian': 'Languages',
  'italian': 'Languages',
  
  // Cooking
  'cooking': 'Cooking',
  'baking': 'Cooking',
  'chef': 'Cooking',
  'pastry': 'Cooking',
  
  // Art
  'painting': 'Art',
  'drawing': 'Art',
  'design': 'Art',
  'photography': 'Art',
  };

  static String detectCategory(String skillName) {
    if (skillName.isEmpty) return 'Other';
    
    final lowerValue = skillName.trim().toLowerCase();
    
    var sortedKeys = kSkillKeywordMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in sortedKeys) {
      if (lowerValue.contains(key.toLowerCase())) {
        return kSkillKeywordMap[key]!;
      }
    }
    return 'Other';
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
