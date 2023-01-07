import 'package:latlong2/latlong.dart';

/// Questa classe rappresenta un luogo
class Place {
  late final int id;
  late final String name;
  late final int co2Level;
  late final LatLng location;

  Place(this.id, this.name, this.co2Level, this.location);

  /// Ottiene un luogo da un json
  Place.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    try {
      co2Level = json['co2'];
    } catch (e) {
      co2Level = 400;
    }
    location = LatLng(json['lat'], json['lon']);
  }

  /// Un posto è uguale all'altro se hanno stesso id, nome e luogo
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Place &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              location == other.location;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ location.hashCode;
}
