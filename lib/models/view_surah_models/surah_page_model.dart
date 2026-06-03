import 'ayah_model.dart';

class SurahPageModel {
  SurahPageModel({
    required this.pageNumber,
    required this.jozz,
    required this.ayahs,
  });

  final int pageNumber;
  final String jozz;
  final List<AyahModel> ayahs;

  factory SurahPageModel.fromAyahs(List<AyahModel> ayahs) {
    return SurahPageModel(
      pageNumber: int.tryParse(ayahs.first.page) ?? 0,
      jozz: ayahs.first.jozz,
      ayahs: ayahs,
    );
  }
}
