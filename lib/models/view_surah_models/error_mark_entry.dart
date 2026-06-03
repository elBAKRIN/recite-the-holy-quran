class ErrorMarkEntry {
  ErrorMarkEntry({
    required this.id,
    required this.surahId,
    required this.ayahId,
    required this.ayahNumber,
    required this.page,
    required this.surahName,
    required this.ayahText,
    required this.wordIndices,
  });

  final String id;
  final int surahId;
  final String ayahId;
  final int ayahNumber;
  final int page;
  final String surahName;
  final String ayahText;
  final Set<int> wordIndices;

  factory ErrorMarkEntry.fromJson(Map<String, dynamic> json) {
    return ErrorMarkEntry(
      id: json['id'] as String,
      surahId: json['surahId'] as int,
      ayahId: json['ayahId'] as String,
      ayahNumber: json['ayahNumber'] as int,
      page: json['page'] as int,
      surahName: json['surahName'] as String,
      ayahText: json['ayahText'] as String,
      wordIndices: Set<int>.from(json['wordIndices'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahId': surahId,
      'ayahId': ayahId,
      'ayahNumber': ayahNumber,
      'page': page,
      'surahName': surahName,
      'ayahText': ayahText,
      'wordIndices': wordIndices.toList(),
    };
  }

  bool isWordMarked(int wordIndex) => wordIndices.contains(wordIndex);

  void toggleWord(int wordIndex) {
    if (wordIndices.contains(wordIndex)) {
      wordIndices.remove(wordIndex);
    } else {
      wordIndices.add(wordIndex);
    }
  }

  bool get isEmpty => wordIndices.isEmpty;
}
