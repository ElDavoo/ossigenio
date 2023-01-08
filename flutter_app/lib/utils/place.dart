import 'package:latlong2/latlong.dart';

/// Questa classe rappresenta un luogo
class Place {
  /// L'id del luogo
  late final int id;

  /// Il nome del luogo
  late final String name;

  /// La concentrazione attuale di CO2 in ppm nel luogo
  late final int co2Level;

  /// La posizione del luogo
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
