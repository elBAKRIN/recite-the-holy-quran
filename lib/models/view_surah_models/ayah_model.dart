class AyahModel {
  AyahModel({
    required this.ayahNumber,
    required this.text,
    required this.page,
    required this.id,
    required this.jozz,
  });

  final int ayahNumber;
  final String text;
  final String page;
  final String id;
  final String jozz;

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      ayahNumber: int.tryParse(json['aya_no'].toString()) ?? 0,
      text: json['aya_text']?.toString() ?? '',
      page: json['page']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      jozz: json['jozz']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aya_no': ayahNumber,
      'aya_text': text,
      'page': page,
      'id': id,
      'jozz': jozz,
    };
  }
}
