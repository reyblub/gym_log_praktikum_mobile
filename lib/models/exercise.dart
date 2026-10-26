import 'package:html/parser.dart' as html;

/// Model terpisah dari widget agar mudah dikembangkan pada UAS.
class ExerciseCategory {
  const ExerciseCategory({required this.id, required this.name});

  final int id;
  final String name;

  String get label =>
      const {
        'Abs': 'Perut',
        'Arms': 'Lengan',
        'Back': 'Punggung',
        'Calves': 'Betis',
        'Cardio': 'Kardio',
        'Chest': 'Dada',
        'Legs': 'Kaki',
        'Shoulders': 'Bahu',
      }[name] ??
      name;

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) =>
      ExerciseCategory(id: _asInt(json['id']), name: _asString(json['name']));

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.equipment,
    required this.muscles,
    required this.languageLabel,
    required this.author,
    required this.licenseName,
    required this.licenseUrl,
    required this.imageAuthor,
    required this.imageLicense,
    required this.imageLicenseUrl,
    this.imageUrl,
    this.thumbnailUrl,
    this.isLocal = false,
  });

  final int id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final List<String> equipment;
  final List<String> muscles;
  final String languageLabel;
  final String author;
  final String licenseName;
  final String licenseUrl;
  final String imageAuthor;
  final String imageLicense;
  final String imageLicenseUrl;
  final String? imageUrl;
  final String? thumbnailUrl;
  final bool isLocal;

  String get equipmentLabel =>
      equipment.isEmpty ? 'Alat tidak dicantumkan' : equipment.join(', ');

  String get sourceUrl =>
      isLocal ? '' : 'https://wger.de/en/exercise/$id/view/';

  /// Data contoh praktikum memakai schema lokal yang lebih sederhana.
  factory Exercise.fromLocalJson(
    Map<String, dynamic> json, {
    required ExerciseCategory category,
  }) =>
      Exercise(
        id: _asInt(json['id']),
        name: _asString(json['name']).trim(),
        description: _asString(json['description']).trim(),
        category: category,
        equipment: _strings(json['equipment']),
        muscles: _strings(json['muscles']),
        languageLabel: 'Indonesia',
        author: 'GymLog',
        licenseName: 'MIT (data contoh)',
        licenseUrl: '',
        imageAuthor: '',
        imageLicense: '',
        imageLicenseUrl: '',
        isLocal: true,
      );

  factory Exercise.fromApiJson(Map<String, dynamic> json) {
    final translations = _maps(json['translations']);
    // Endpoint terbaru mengelompokkan terjemahan dalam translations.
    // Bahasa Inggris dipilih karena antarmuka memakai data language__code=en.
    var translation = json;
    if (translations.isNotEmpty) {
      translation = translations.firstWhere(
        (value) =>
            value['language'] == 2 ||
            (value['language'] is Map && value['language']['code'] == 'en'),
        orElse: () => translations.first,
      );
    }
    final images = _maps(json['images']);
    final image = images.isEmpty
        ? <String, dynamic>{}
        : images.firstWhere(
            (value) => value['is_main'] == true,
            orElse: () => images.first,
          );
    final thumbnails = _map(image['thumbnails']);
    final baseLicense = _map(json['license']);
    final textLicense = _resolveLicense(translation['license'], baseLicense);
    final pictureLicense = _resolveLicense(image['license'], baseLicense);
    final rawDescription = _asString(translation['description']);
    final language = translation['language'];

    return Exercise(
      id: _asInt(json['id']),
      name: _asString(translation['name']).trim().isEmpty
          ? 'Latihan #${_asInt(json['id'])}'
          : _asString(translation['name']).trim(),
      description: plainText(
        rawDescription.isNotEmpty
            ? rawDescription
            : _asString(translation['description_source']),
      ),
      category: ExerciseCategory.fromJson(_map(json['category'])),
      equipment: _maps(json['equipment'])
          .map((value) => _equipmentLabel(_asString(value['name'])))
          .where((value) => value.isNotEmpty)
          .toList(),
      muscles: _maps(json['muscles'])
          .map(
            (value) => _asString(value['name_en']).isNotEmpty
                ? _asString(value['name_en'])
                : _asString(value['name']),
          )
          .where((value) => value.isNotEmpty)
          .toList(),
      languageLabel:
          language == 2 || (language is Map && language['code'] == 'en')
              ? 'Inggris'
              : 'Mengikuti sumber',
      imageUrl: _imageUrl(image['image']),
      thumbnailUrl: _imageUrl(thumbnails['medium']) ??
          _imageUrl(thumbnails['small']) ??
          _imageUrl(image['image']),
      author: _firstText([
        translation['license_author'],
        json['license_author'],
        'Kontributor wger',
      ]),
      licenseName: textLicense.$1,
      licenseUrl: textLicense.$2,
      imageAuthor: _firstText([image['license_author'], 'Kontributor wger']),
      imageLicense: pictureLicense.$1,
      imageLicenseUrl: pictureLicense.$2,
    );
  }

  // Favorit menyimpan salinan data yang dipilih agar detail tetap terbaca offline.
  Map<String, dynamic> toStoredJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.toJson(),
        'equipment': equipment,
        'muscles': muscles,
        'languageLabel': languageLabel,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'isLocal': isLocal,
        'author': author,
        'licenseName': licenseName,
        'licenseUrl': licenseUrl,
        'imageAuthor': imageAuthor,
        'imageLicense': imageLicense,
        'imageLicenseUrl': imageLicenseUrl,
      };

  factory Exercise.fromStoredJson(Map<String, dynamic> json) => Exercise(
        id: _asInt(json['id']),
        name: _asString(json['name']),
        description: _asString(json['description']),
        category: ExerciseCategory.fromJson(_map(json['category'])),
        equipment: _strings(json['equipment']),
        muscles: _strings(json['muscles']),
        languageLabel: _asString(json['languageLabel']),
        imageUrl: _imageUrl(json['imageUrl']),
        thumbnailUrl: _imageUrl(json['thumbnailUrl']),
        isLocal: json['isLocal'] == true,
        author: _asString(json['author']),
        licenseName: _asString(json['licenseName']),
        licenseUrl: _asString(json['licenseUrl']),
        imageAuthor: _asString(json['imageAuthor']),
        imageLicense: _asString(json['imageLicense']),
        imageLicenseUrl: _asString(json['imageLicenseUrl']),
      );
}

class ExercisePage {
  const ExercisePage({
    required this.items,
    required this.total,
    this.nextOffset,
  });
  final List<Exercise> items;
  final int total;
  final int? nextOffset;
}

String plainText(String value) {
  final spaced = value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(
        RegExp(r'</(?:p|div|h[1-6]|li)>', caseSensitive: false),
        '\n\n',
      );
  final document = html.parse(spaced);
  for (final element in document.querySelectorAll('script, style')) {
    element.remove();
  }
  return (document.body?.text ?? '')
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : [];
List<String> _strings(dynamic value) =>
    value is List ? value.whereType<String>().toList() : [];
int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String _asString(dynamic value) => value is String ? value : '';
String _firstText(List<dynamic> values) =>
    values.map(_asString).firstWhere((value) => value.trim().isNotEmpty);
String? _imageUrl(dynamic value) {
  final uri = Uri.tryParse(_asString(value));
  if (uri == null ||
      !uri.hasAuthority ||
      !['http', 'https'].contains(uri.scheme)) {
    return null;
  }
  return uri.scheme == 'http' && uri.host == 'wger.de'
      ? uri.replace(scheme: 'https').toString()
      : uri.toString();
}

(String, String) _resolveLicense(dynamic value, Map<String, dynamic> fallback) {
  if (value is Map) {
    return (_asString(value['short_name']), _asString(value['url']));
  }
  final id = _asInt(value);
  if (id == 0 || id == _asInt(fallback['id'])) {
    return (
      _firstText([fallback['short_name'], 'Lihat sumber wger']),
      _asString(fallback['url']),
    );
  }
  // ID lisensi publik pada API wger. ID lain tetap diarahkan ke sumber.
  return switch (id) {
    1 => ('CC-BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0/'),
    2 => ('CC-BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0/'),
    _ => ('Lisensi #$id — lihat sumber wger', ''),
  };
}

String _equipmentLabel(String name) =>
    const {
      'Barbell': 'Barbel',
      'Bench': 'Bangku',
      'Incline bench': 'Bangku miring',
      'Pull-up bar': 'Palang pull-up',
      'Cable': 'Kabel',
      'Mat': 'Matras',
      'Bodyweight': 'Berat badan',
      'none (bodyweight exercise)': 'Berat badan',
    }[name] ??
    name;
