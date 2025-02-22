import 'dart:async';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/pages/achievement.dart';
import 'package:faulkner_footsteps/pages/map_display.dart';
import 'package:faulkner_footsteps/widgets/logout_button.dart';
import 'package:faulkner_footsteps/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faulkner_footsteps/objects/list_item.dart';
import 'package:faulkner_footsteps/pages/start_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ListPage extends StatefulWidget {
  ListPage({super.key});

  ApplicationState app_state = ApplicationState();

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  static LatLng? _currentPosition;
  void getlocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    double lat = position.latitude;
    double long = position.longitude;
    setState(() {
      _currentPosition = LatLng(lat, long);
    });
  }

  void _update(Timer timer) {
    setState(() {});
    if (displaySites.isNotEmpty) {
      updateTimer.cancel();
    }
  }
  //not sure if this code is important, I will leave it in for now
  // Future<void> showRatingDialog() async {
  //   await showDialog<double>(
  //     context: context,
  //     builder: (BuildContext context) => RatingDialog(widget.app_state, ),
  //   );
  // }

  late Timer updateTimer;
  late List<HistSite> fullSiteList;
  late List<HistSite> displaySites;
  late SearchController _searchController;
  @override
  void initState() {
    getlocation();
    updateTimer = Timer.periodic(const Duration(milliseconds: 500), _update);
    displaySites = widget.app_state.historicalSites;
    fullSiteList = widget.app_state.historicalSites;
    _searchController = SearchController();
    super.initState();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapDisplay(
              currentPosition: _currentPosition!, appState: widget.app_state),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    updateTimer.cancel();
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: displaySites.length,
            itemBuilder: (BuildContext context, int index) {
              HistSite site = displaySites[index];
              return ListItem(
                  app_state: widget.app_state,
                  siteInfo: site,
                  currentPosition: _currentPosition ?? LatLng(0, 0));
            },
          ),
        ),
      ],
    );
  }

  void setDisplayItems() {
    if (fullSiteList.isEmpty) {
      fullSiteList = widget.app_state.historicalSites;
      displaySites = fullSiteList;
    }
  }

  void openSearchDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            alignment: Alignment.topCenter,
            title: Text("Search"),
            content: SearchBar(
              leading: Icon(Icons.search),
              controller: _searchController,
              hintText: "Search",
              onSubmitted: (query) {
                List<HistSite> lst = [];
                lst.addAll(fullSiteList.where((HistSite site) =>
                    site.name.toLowerCase().contains(query.toLowerCase())));
                setState(() {
                  displaySites = lst;
                });
                Navigator.pop(context);
              },
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    while (_currentPosition == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    setDisplayItems(); //this is here so that it loads initially. Otherwise nothing loads.
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 214, 196),
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 107, 79, 79),
          elevation: 5.0,
          actions: [
            const ProfileButton(),
            IconButton(
              onPressed: () {
                openSearchDialog();
              },
              icon: const Icon(Icons.search,
                  color: Color.fromARGB(255, 255, 243, 228)),
            ),
            const LogoutButton(),
          ],
          title: Container(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 50),
            child: FittedBox(
              child: Text(
                _selectedIndex == 0
                    ? "Historical Sites"
                    : _selectedIndex == 1
                        ? "Map"
                        : "Achievements",
                style: GoogleFonts.ultra(
                    textStyle: const TextStyle(
                        color: Color.fromARGB(255, 255, 243, 228)),
                    fontSize: 99),
              ),
            ),
          )),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
              ? MapDisplay(
                  currentPosition: _currentPosition!,
                  appState: widget.app_state,
                )
              : const AchievementsPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 107, 79, 79),
        selectedItemColor: const Color.fromARGB(255, 238, 214, 196),
        unselectedItemColor: const Color.fromARGB(200, 238, 214, 196),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),

      // Uncomment to add sites
      /*
      floatingActionButton: FloatingActionButton(onPressed: () {
        showDialog(
            context: context,
            builder: (_) {
              return SiteDialogue(siteAdded: widget.app_state.addSite);
            });
      }),
      */
    );
  }
}
