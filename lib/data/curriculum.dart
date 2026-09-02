import '../models/unit.dart';
import 'units/unit_01.dart';
import 'units/unit_02.dart';
import 'units/unit_03.dart';
import 'units/unit_04.dart';
import 'units/unit_05.dart';
import 'units/unit_06.dart';
import 'units/unit_07.dart';
import 'units/unit_08.dart';
import 'units/unit_09.dart';

export 'units/unit_01.dart';
export 'units/unit_02.dart';
export 'units/unit_03.dart';
export 'units/unit_04.dart';
export 'units/unit_05.dart';
export 'units/unit_06.dart';
export 'units/unit_07.dart';
export 'units/unit_08.dart';
export 'units/unit_09.dart';

const List<Unit> curriculum = [
  unit01,
  unit02,
  unit03,
  unit04,
  unit05,
  unit06,
  unit07,
  unit08,
  unit09,
];

Unit unitById(int id) {
  return curriculum.firstWhere(
    (unit) => unit.id == id,
    orElse: () => throw ArgumentError('No unit found with id $id'),
  );
}
