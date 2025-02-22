import 'dart:async';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:faulkner_footsteps/objects/info_text.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'firebase_options.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  StreamSubscription<QuerySnapshot>? _siteSubscription;
  Set<String> _visitedPlaces = {};
  Set<String> get visitedPlaces => _visitedPlaces;

  List<HistSite> _historicalSites = [];
  List<HistSite> get historicalSites => _historicalSites;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) async {
      if (user != null) {
        _loggedIn = true;

        // Load achievements when user logs in
        await loadAchievements();

        _siteSubscription = FirebaseFirestore.instance
            .collection('sites')
            .snapshots()
            .listen((snapshot) {
          _historicalSites = [];
          for (final document in snapshot.docs) {
            var blurbCont = document.data()["blurbs"];
            List<String> blurbStrings = blurbCont.split("{ListDiv}");
            List<InfoText> newBlurbs = [];
            for (var blurb in blurbStrings) {
              List<String> values = blurb.split("{IFDIV}");
              newBlurbs.add(InfoText(
                  title: values[0], value: values[1], date: values[2]));
            }
            _historicalSites.add(HistSite(
              name: document.data()["name"] as String,
              description: document.data()["description"] as String,
              blurbs: newBlurbs,
              imageUrls: List<String>.from(document.data()["images"]),
              images: [],
              lat: document.data()["lat"] as double,
              lng: document.data()["lng"] as double,
              //added ratings
              //set as 0.0 for testing, will have to change later to have consistent ratings
              avgRating: document.data()["avgRating"] != null
                  ? (document.data()["avgRating"] as num).toDouble()
                  : 0.0,
              ratingAmount: document.data()["ratingCount"] != null
                  ? document.data()["ratingCount"] as int
                  : 0,
            ));
          }
          notifyListeners();
        });
      } else {
        _loggedIn = false;
        _historicalSites = [];
        _visitedPlaces = {};
        _siteSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  void addSite(HistSite newSite) {
    //using the variable to contain information for sake of readability. May refactor later
    // if(!_loggedIn) { UNCOMMENT THIS LATER. COMMENTED OUT FOR TESTING PURPOSES
    //   throw Exception("Must be logged in");
    // }

    var data = {
      "name": newSite.name,
      "description": newSite.description,
      "blurbs": newSite.listifyBlurbs(),
      "images": "testValue",
      //added ratings here
      "avgRating": newSite.avgRating,
      "ratingAmount": newSite.ratingAmount,
    };

    print('Adding site with $data');
    FirebaseFirestore.instance.collection("sites").doc(newSite.name).set(data);
    FirebaseFirestore.instance
        .collection("sites")
        .doc(newSite.name)
        .collection("ratings");
  }

  Future<double> getUserRating(String siteName) async {
    if (!_loggedIn) return 0.0;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("sites")
          .doc(siteName)
          .collection("ratings")
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return docSnapshot.get("rating");
        } else {
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } catch (e) {
      print("error");
      return 0.0;
    }
  }

  //update/store rating in firebase
  void updateSiteRating(String siteName, double newRating) async {
    final site = _historicalSites.firstWhere((s) => s.name == siteName);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    double totalRating = 0;
    int ratingcount = 0;
    FirebaseFirestore.instance
        .collection("sites")
        .doc(siteName)
        .collection("ratings")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({"rating": newRating});
    await FirebaseFirestore.instance
        .collection("sites")
        .doc(siteName)
        .collection("ratings")
        .get()
        .then((snapshot) {
      for (final doc in snapshot.docs) {
        totalRating += doc.data()["rating"];
        ratingcount += 1;
        // print("AppState Total Rating: $totalRating");
        // print("AppState Rating Count: $ratingcount");
      }
    });
    double finalRating = totalRating / ratingcount;
    // print("This is a final rating $finalRating");

    FirebaseFirestore.instance
        .collection("sites")
        .doc(siteName)
        .update({"avgRating": finalRating, "ratingCount": ratingcount});
    notifyListeners();
  }

  // Achievement Management Methods
  Future<void> loadAchievements() async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('places')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['visited'] != null) {
          _visitedPlaces = Set<String>.from(data['visited'] as List);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  Future<void> saveAchievement(String place) async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      _visitedPlaces.add(place);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('places')
          .set({
        'visited': _visitedPlaces.toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error saving achievement: $e');
    }
  }

  bool hasVisited(String place) {
    return _visitedPlaces.contains(place);
  }

  Map<String, LatLng> getLocations() {
    int i = 0;
    Map<String, LatLng> sites = {};
    while (i < historicalSites.length) {
      sites[historicalSites[i].name] =
          LatLng(historicalSites[i].lat, historicalSites[i].lng);
      i++;
    }
    return sites;
  }
}
