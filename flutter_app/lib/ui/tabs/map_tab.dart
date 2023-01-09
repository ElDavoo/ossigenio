import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/ui/pages/place_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../managers/account_man.dart';
import '../../utils/constants.dart';
import '../../utils/place.dart';
import '../../utils/ui.dart';

/// UI della mappa
class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  /// Controller dei popup
  final PopupController _popupController = PopupController();
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;

  /// Lista dei marker da mostrare sulla mappa
  List<Marker> _markers = [];

  /// Lista dei luoghi, associati ai marker
  List<Place> _places = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
    _refresh();
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  /// Costruisce un popup di un marker.
  Widget _popupBuilder(BuildContext context, marker) {
    // Cerchiamo un Place con la stessa posizione del marker selezionato
    final place =
        _places.firstWhere((element) => element.location == marker.point);
    return Container(
      width: 200,
      height: 150,
      decoration: UI.gradientBox(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                AppLocalizations.of(context)!.actualCO2(place.co2Level),
                style: const TextStyle(
                  fontSize: 40,
                ),
              ),
            ),
            // Button to go to the place's page
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PredictionPlace(place: place)),
                );
              },
              child: Text(AppLocalizations.of(context)!.predictions),
            ),
          ],
        ),
      ),
    );
  }

  /// Chiede manualmente i luoghi al server
  void _refresh() {
    AccountManager().getPlaces(GpsManager.position.value!).then((value) {
      _places = value;
      _onNearbyPlacesChanged(value);
    });
  }

  /// Aggiorna la lista dei marker
  void _onNearbyPlacesChanged(List<Place> coords) {
    setState(() {
      _markers = _placetomarkers(coords);
    });
  }

  /// Converte una lista di Place in una lista di Marker
  static List<Marker> _placetomarkers(List<Place> coords) {
    return coords.map((point) {
      return Marker(
        point: point.location,
        width: 45,
        height: 45,
        builder: (context) => Icon(
          Icons.location_on_outlined,
          size: 45,
          color: UI.decideColor(point.co2Level),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FlutterMap(
      options: MapOptions(
        onTap: (_, __) {
          _popupController.hideAllPopups();
        },
        center: C.defaultLocation,
        minZoom: 9.0,
        zoom: 15.0,
        maxZoom: 21.0,
        maxBounds: C.italyBounds,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            setState(
              () => _centerOnLocationUpdate = CenterOnLocationUpdate.never,
            );
          }
        },
      ),
      nonRotatedChildren: [
        Positioned(
          right: 20,
          bottom: 20,
          child: InkWell(
            onLongPress: _refresh,
            child: FloatingActionButton(
              onPressed: () {
                // Automatically center the location marker on the map when location updated until user interact with the map.
                setState(
                  () => _centerOnLocationUpdate = CenterOnLocationUpdate.always,
                );
                // Center the location marker on the map and zoom the map to level 18.
                _centerCurrentLocationStreamController.add(18);
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: C.tileUrl,
          tileProvider: FMTC.instance(C.fmtcStoreName).getTileProvider(),
          maxNativeZoom: 18.0,
        ),
        CurrentLocationLayer(
          centerCurrentLocationStream:
              _centerCurrentLocationStreamController.stream,
          centerOnLocationUpdate: _centerOnLocationUpdate,
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            spiderfyCircleRadius: 80,
            spiderfySpiralDistanceMultiplier: 2,
            circleSpiralSwitchover: 12,
            maxClusterRadius: 120,
            rotate: true,
            size: const Size(40, 40),
            anchor: AnchorPos.align(AnchorAlign.center),
            fitBoundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(50),
              maxZoom: 15,
            ),
            markers: _markers,
            polygonOptions: const PolygonOptions(
                borderColor: Colors.blueAccent,
                color: Colors.black12,
                borderStrokeWidth: 3),
            popupOptions: PopupOptions(
                popupState: PopupState(),
                popupSnap: PopupSnap.markerTop,
                popupController: _popupController,
                popupBuilder: _popupBuilder),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.blue),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
