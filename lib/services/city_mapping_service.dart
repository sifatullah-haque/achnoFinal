import 'package:flutter/foundation.dart';

class CityMappingService {
  // Static map of city variations to their canonical names
  static const Map<String, String> _cityMappings = {
    // Casablanca variations
    'casablanca': 'Casablanca',
    'الدار البيضاء': 'Casablanca',
    'casa': 'Casablanca',
    'dar el beida': 'Casablanca',

    // Rabat
    'rabat': 'Rabat',
    'الرباط': 'Rabat',

    // Sale / Salé
    'sale': 'Salé',
    'salé': 'Salé',
    'سلا': 'Salé',

    // Fez
    'fez': 'Fez',
    'fès': 'Fez',
    'فاس': 'Fez',

    // Marrakesh
    'marrakech': 'Marrakech',
    'marrakesh': 'Marrakech',
    'مراكش': 'Marrakech',

    // Tangier
    'tangier': 'Tangier',
    'tanger': 'Tangier',
    'طنجة': 'Tangier',

    // Agadir
    'agadir': 'Agadir',
    'أكادير': 'Agadir',

    // Meknes
    'meknes': 'Meknes',
    'meknès': 'Meknes',
    'مكناس': 'Meknes',

    // Oujda
    'oujda': 'Oujda',
    'وجدة': 'Oujda',

    // Kenitra
    'kenitra': 'Kenitra',
    'القنيطرة': 'Kenitra',

    // Tetouan
    'tetouan': 'Tetouan',
    'tétouan': 'Tetouan',
    'تطوان': 'Tetouan',

    // Temara
    'temara': 'Temara',
    'تمارة': 'Temara',

    // Safi
    'safi': 'Safi',
    'آسفي': 'Safi',

    // Mohammedia
    'mohammedia': 'Mohammedia',
    'المحمدية': 'Mohammedia',

    // Khouribga
    'khouribga': 'Khouribga',
    'خريبكة': 'Khouribga',

    // Beni Mellal
    'beni mellal': 'Beni Mellal',
    'بني ملال': 'Beni Mellal',

    // El Jadida
    'el jadida': 'El Jadida',
    'الجديدة': 'El Jadida',

    // Nador
    'nador': 'Nador',
    'الناظور': 'Nador',

    // Settat
    'settat': 'Settat',
    'سطات': 'Settat',

    // Larache
    'larache': 'Larache',
    'العرائش': 'Larache',

    // Ksar el Kebir
    'ksar el kebir': 'Ksar el Kebir',
    'القصر الكبير': 'Ksar el Kebir',

    // Berrechid
    'berrechid': 'Berrechid',
    'برشيد': 'Berrechid',

    // Khemisset
    'khemisset': 'Khemisset',
    'الخميسات': 'Khemisset',

    // Errachidia
    'errachidia': 'Errachidia',
    'الراشيدية': 'Errachidia',

    // Ouarzazate
    'ouarzazate': 'Ouarzazate',
    'ورزازات': 'Ouarzazate',

    // Tiznit
    'tiznit': 'Tiznit',
    'تزنيت': 'Tiznit',

    // Essaouira
    'essaouira': 'Essaouira',
    'الصويرة': 'Essaouira',

    // Al Hoceima
    'al hoceima': 'Al Hoceima',
    'الحسيمة': 'Al Hoceima',

    // Beni Ansar
    'beni ansar': 'Beni Ansar',
    'بني أنصار': 'Beni Ansar',

    // Berkane
    'berkane': 'Berkane',
    'بركان': 'Berkane',

    // Taourirt
    'taourirt': 'Taourirt',
    'تاوريرت': 'Taourirt',

    // Guercif
    'guercif': 'Guercif',
    'غيرسيف': 'Guercif',

    // Ouezzane
    'ouezzane': 'Ouezzane',
    'وزان': 'Ouezzane',

    // Guelmim
    'guelmim': 'Guelmim',
    'كلميم': 'Guelmim',

    // Bni Ansar already mapped; replicate 'bni ansar' etc.

    // Oued Zem
    'oued zem': 'Oued Zem',
    'واد زم': 'Oued Zem',

    // Fquih Ben Salah
    'fquih ben salah': 'Fquih Ben Salah',
    'فقيه بنصالح': 'Fquih Ben Salah',

    // Sidi Slimane
    'sidi slimane': 'Sidi Slimane',
    'سيدي سليمان': 'Sidi Slimane',

    // Sidi Kacem
    'sidi kacem': 'Sidi Kacem',
    'سيدي قاسم': 'Sidi Kacem',

    // Khenifra
    'khenifra': 'Khenifra',
    'خنيفرة': 'Khenifra',

    // Ifrane
    'ifran': 'Ifrane',
    'إفران': 'Ifrane',

    // Taroudant
    'taroudant': 'Taroudant',
    'تارودانت': 'Taroudant',

    // Taza
    'taza': 'Taza',

    'تازة': 'Taza',

    // Ait Melloul
    'ait melloul': 'Ait Melloul',
    'آيت ملول': 'Ait Melloul',

    // El Aaiun (Laayoune)
    'el aaiun': 'Laayoune',
    'العيون': 'Laayoune',
    'laayoune': 'Laayoune',

    // Dakhla
    'dakhla': 'Dakhla',
    'الداخلة': 'Dakhla',

    // Chefchaouen
    'chefchaouen': 'Chefchaouen',
    'شفشاون': 'Chefchaouen',

    // Azrou
    'azrou': 'Azrou',
    'أزرو': 'Azrou',

    // Midelt
    'midelt': 'Midelt',
    'ميدلت': 'Midelt',

    // Skhirate
    'skhirate': 'Skhirate',
    'الصخيرات': 'Skhirate',

    // Martil
    'martil': 'Martil',
    'مرتيل': 'Martil',

    // Tinghir
    'tinghir': 'Tinghir',
    'تنغير': 'Tinghir',

    // Zagora
    'zagora': 'Zagora',
    'زكورة': 'Zagora',

    // El Kelaa Des Sraghna
    'el kelaa des sraghna': 'El Kelaa des Sraghna',
    'القليعة السرحانية': 'El Kelaa des Sraghna',

    // Souk el Arbaa (Souk as-Sabt)
    'souk el arbaa': 'Souk El Arbaa',
    'سوق السبت': 'Souk El Arbaa',

    // Bouskoura
    'bouskoura': 'Bouskoura',
    'بوسكورة': 'Bouskoura',

    // Berkane already; etc...

    // Note: adjust duplicates or missing.
  };

  /// Normalizes a city name to its canonical form
  /// Returns the canonical city name if found, otherwise returns the cleaned input
  static String normalizeCityName(String cityName) {
    if (cityName.isEmpty) return cityName;

    // Clean the input: trim whitespace and convert to lowercase for matching
    final cleanInput = cityName.trim().toLowerCase();

    // Check direct mapping first
    if (_cityMappings.containsKey(cleanInput)) {
      return _cityMappings[cleanInput]!;
    }

    // Check for partial matches (for cases where Google Places returns longer descriptions)
    for (final key in _cityMappings.keys) {
      if (cleanInput.contains(key) || key.contains(cleanInput)) {
        return _cityMappings[key]!;
      }
    }

    // If no mapping found, return the original input with proper casing
    return _capitalizeWords(cityName.trim());
  }

  /// Checks if two city names refer to the same city
  static bool areSameCity(String city1, String city2) {
    if (city1.isEmpty || city2.isEmpty) return false;

    final normalized1 = normalizeCityName(city1);
    final normalized2 = normalizeCityName(city2);

    return normalized1.toLowerCase() == normalized2.toLowerCase();
  }

  /// Helper method to capitalize words properly
  static String _capitalizeWords(String input) {
    if (input.isEmpty) return input;

    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Gets all known variations of a city name
  static List<String> getCityVariations(String cityName) {
    final normalized = normalizeCityName(cityName);

    final variations = <String>[];
    for (final entry in _cityMappings.entries) {
      if (entry.value == normalized) {
        variations.add(entry.key);
      }
    }

    return variations;
  }

  /// Adds a new city mapping (useful for dynamic additions)
  static void addCityMapping(String variation, String canonical) {
    // Note: Since _cityMappings is const, this would require converting it to a regular Map
    // For now, this serves as a placeholder for future extensibility
    debugPrint('City mapping request: $variation -> $canonical');
  }
}
