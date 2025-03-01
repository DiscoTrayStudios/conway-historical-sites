import 'dart:collection';
import 'dart:convert';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/pin_Dialog.dart';
import 'package:faulkner_footsteps/pages/achievement.dart';
import 'package:faulkner_footsteps/pages/hist_site_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:provider/provider.dart';

class MapDisplay extends StatefulWidget {
  final LatLng currentPosition;
  final ApplicationState appState;
  final LatLng initialPosition;
  const MapDisplay(
      {super.key,
      required this.currentPosition,
      required this.initialPosition,
      required this.appState});

  @override
  _MapDisplayState createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  bool visited = false;
  final Distance distance = new Distance();
  late Map<String, LatLng> siteLocations = widget.appState.getLocations();
  late Map<String, double> siteDistances = getDistances(siteLocations);
  late var sorted = Map.fromEntries(siteDistances.entries.toList()
    ..sort((e1, e2) => e1.value.compareTo(e2.value)));
  late var sortedlist = sorted.values.toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => locationDialog(context));
  }

  void locationDialog(context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);
    HistSite? selectedSite = widget.appState.historicalSites.firstWhere(
      (site) => site.name == sorted.keys.first.toString(),
      // if not found, it will say the following
      orElse: () => HistSite(
        name: sorted.keys.first,
        description: "No description available",
        blurbs: [],
        images: [],
        imageUrls: [],
        lat: 0,
        lng: 0,
        avgRating: 0.0,
        ratingAmount: 0,
      ),
    );
    if ((sorted.values.first < 30000.0) &
        (!widget.appState.hasVisited(sorted.keys.first)) &
        !visited) {
      showDialog(
          context: context,
          builder: (
            BuildContext context,
          ) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 247, 222, 231),
              title: Text(sorted.keys.first,
                  style: GoogleFonts.ultra(
                      textStyle: const TextStyle(
                          color: Color.fromARGB(255, 72, 52, 52),
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("You are near this historical site!",
                      style: GoogleFonts.rakkas(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 107, 79, 79),
                              fontSize: 14))),
                  Image(
                      image: MemoryImage(
                          base64Decode(selectedSite.imageUrls.first))),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate User to the HistSitePage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistSitePage(
                                histSite: selectedSite,
                                app_state: widget.appState,
                                currentPosition: widget.currentPosition,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "Get Info      ",
                          style: GoogleFonts.rakkas(
                              textStyle: const TextStyle(
                                  color: Color.fromARGB(255, 107, 79, 79),
                                  fontSize: 20)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          var AchievementState = AchievementsPageState();
                          // Navigate User to the HistSitePage
                          AchievementState.visitPlace(
                              context, sorted.keys.first);
                          visited = true;
                        },
                        child: Text(
                          "Mark as visited",
                          style: GoogleFonts.rakkas(
                              textStyle: const TextStyle(
                                  color: Color.fromARGB(255, 107, 79, 79),
                                  fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      var AchievementState = AchievementsPageState();
                      // Navigate User to the HistSitePage
                      AchievementState.visitPlace(context, sorted.keys.first);
                      visited = true;
                    },
                    child: Text(
                      "Close",
                      style: GoogleFonts.rakkas(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 107, 79, 79),
                              fontSize: 20)),
                    ),
                  ),
                ],
              ),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        // Red colored pins for each historical site
        List<Marker> markers = siteLocations.entries.map((entry) {
          return Marker(
            point: entry.value,
            child: IconButton(
              icon: const Icon(Icons.location_pin,
                  color: Color.fromARGB(255, 255, 70, 57), size: 30),
              onPressed: () {
                // Show PinDialog when a pin is clicked
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PinDialog(
                      siteName: entry.key,
                      appState: appState,
                      currentPosition: widget.currentPosition,
                    );
                  },
                );
              },
            ),
          );
        }).toList();
        markers.add(Marker(
            point: widget.currentPosition,
            child: Icon(
              Icons.circle,
              color: Colors.blue,
            )));
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 238, 214, 196),
          appBar: AppBar(
            leading: BackButton(
              color: Color.fromARGB(255, 255, 243, 228),
            ),
            backgroundColor: const Color.fromARGB(255, 107, 79, 79),
            title: Text(
              "Faulkner County Map",
              style: GoogleFonts.ultra(
                textStyle:
                    const TextStyle(color: Color.fromARGB(255, 255, 243, 228)),
              ),
            ),
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, double> getDistances(Map<String, LatLng> locations) {
    Map<String, double> distances = {};
    for (int i = 0; i < locations.length; i++) {
      distances[locations.keys.elementAt(i)] = distance.as(LengthUnit.Meter,
          locations.values.elementAt(i), widget.currentPosition);
    }
    return distances;
  }
}
