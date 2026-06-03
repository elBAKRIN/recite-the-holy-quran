import 'package:get/get.dart';

import 'ar_trans.dart';
import 'en_trans.dart';
import 'hi_trans.dart';
import 'id_trans.dart';
import 'ml_trans.dart';
import 'ur_trans.dart';
import 'fr_trans.dart';
import 'de_trans.dart';
import 'it_trans.dart';
import 'nl_trans.dart';
import 'es_trans.dart';
import 'wo_trans.dart';
import 'ha_trans.dart';
import 'so_trans.dart';

class MyLocale implements Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    "ar": arT,
    "en": enT,
    "hi": hiT,
    "id": idT,
    "ml": mlT,
    "ur": urT,
    "fr": frT,
    "de": deT,
    "it": itT,
    "nl": nlT,
    "es": esT,
    "wo": woT,
    "ha": haT,
    "so": soT,
  };
}
