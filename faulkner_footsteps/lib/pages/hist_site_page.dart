import 'dart:convert';

import 'package:faulkner_footsteps/app_state.dart';
import 'package:faulkner_footsteps/dialogs/rating_Dialog.dart';
import 'package:faulkner_footsteps/objects/hist_site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';

class HistSitePage extends StatefulWidget {
  final HistSite histSite;
  final LatLng currentPosition;

  const HistSitePage(
      {super.key,
      required this.histSite,
      required this.app_state,
      required this.currentPosition});

  final ApplicationState app_state;

  @override
  State<StatefulWidget> createState() => _HistSitePage();
}

class _HistSitePage extends State<HistSitePage> {
  late double personalRating;
  final Distance _distance = new Distance();

  @override
  void initState() {
    personalRating = 0.0;
    getUserRating();
    super.initState();
  }

  void getUserRating() async {
    personalRating = await widget.app_state.getUserRating(widget.histSite.name);
    setState(() {});
  }

  // Future<void> showRatingDialog() async {
  //   final double? userRating = await showDialog<double>(
  //     context: context,
  //     builder: (BuildContext context) => RatingDialog(
  //       app_state: widget.app_state,
  //       site_name: widget.histSite.name,
  //     ),
  //   );
  //   if (userRating != null) {
  //     setState(() {
  //       personalRating = userRating;
  //     });
  //     widget.histSite.updateRating(userRating);
  //   }
  // }

  // Widget buildRatingStars(double rating) {
  //   int fullStars = rating.floor(); // Full stars
  //   bool halfStar = (rating - fullStars) >= 0.5; // Check if it's a half star
  //   return Row(children: [
  //     Row(
  //       children: List.generate(5, (index) {
  //         if (index < fullStars) {
  //           return const Icon(Icons.star, color: Colors.amber, size: 24);
  //         } else if (index == fullStars && halfStar) {
  //           return const Icon(Icons.star_half, color: Colors.amber, size: 24);
  //         } else {
  //           return const Icon(Icons.star_border, color: Colors.amber, size: 24);
  //         }
  //       }),
  //     ),
  //     Text(" (${widget.histSite.avgRating.toStringAsFixed(1)})",
  //         style: GoogleFonts.rakkas(
  //             textStyle: const TextStyle(
  //                 color: Color.fromARGB(255, 72, 52, 52), fontSize: 16)))
  //   ]);
  // }

  // final urls = [
  //   'https://live.staticflickr.com/2872/9142834823_503dee0d1c_b.jpg',
  //   'https://live.staticflickr.com/3861/14459662112_505397428a_z.jpg',
  //   'https://live.staticflickr.com/5479/14464952611_f462b97d7e_z.jpg',
  //   'https://live.staticflickr.com/5158/14461036375_1892f0c69b.jpg',
  // ];
  /*
  How to add a link to a google drive file
  https://stackoverflow.com/questions/59849232/display-images-from-google-drive-using-networkimage
  */
  @override
  Widget build(BuildContext context) {
    final String siteDistance = (_distance.as(
                LengthUnit.Meter,
                LatLng(widget.histSite.lat, widget.histSite.lng),
                widget.currentPosition) /
            1609.344)
        .toStringAsFixed(2);
    List<String> testList = widget.histSite.imageUrls;
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 238, 214, 196),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 107, 79, 79),
          title: Text(
            "Faulkner Footsteps",
            style: GoogleFonts.ultra(
              textStyle:
                  const TextStyle(color: Color.fromARGB(255, 255, 243, 228)),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.histSite.name,
                      style: GoogleFonts.ultra(
                        textStyle: const TextStyle(
                            color: Color.fromARGB(255, 72, 52, 52),
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text("$siteDistance mi",
                        style: GoogleFonts.ultra(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 72, 52, 52),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                )),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 250, 235, 215),
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: testList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        SwipeImageGallery(
                          context: context,
                          itemBuilder: (context, galleryIndex) {
                            return Image.memory(
                              base64Decode(testList[galleryIndex]),
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                    "assets/images/faulkner_thumbnail.png");
                              },
                            );
                          },
                          itemCount: testList.length,
                        ).show();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          base64Decode(testList[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                                "assets/images/faulkner_thumbnail.png");
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Row(
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       ElevatedButton.icon(
            //         onPressed: showRatingDialog,
            //         icon: const Icon(Icons.star,
            //             color: Color.fromARGB(255, 255, 243, 228), size: 24),
            //         label: const Text("Rate This Site"),
            //         style: ElevatedButton.styleFrom(
            //           foregroundColor: const Color.fromARGB(255, 250, 235, 215),
            //           backgroundColor: const Color.fromARGB(255, 72, 52, 52),
            //           elevation: 6,
            //           shadowColor: Colors.black45,
            //           padding: const EdgeInsets.symmetric(
            //               vertical: 12.0, horizontal: 20.0),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(30.0),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 16.0),
            //       buildRatingStars(widget.histSite.avgRating),
            //       const SizedBox(width: 16.0)
            //       /*
            //       Text(
            //         "${widget.histSite.avgRating.toStringAsFixed(1)} / 5",
            //         style: GoogleFonts.rakkas(
            //           textStyle: const TextStyle(
            //               color: Color.fromARGB(255, 72, 52, 52), fontSize: 16),
            //         ),
            //       ),
            //       */
            //     ],
            //   ),
            // ),
            const SizedBox(height: 16.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                StarRating(
                  rating: personalRating,
                  starCount: 5,
                  onRatingChanged: (rating) {
                    setState(() {
                      widget.histSite.updateRating(
                          personalRating, rating, personalRating == 0.0);
                      personalRating = rating;
                      widget.app_state
                          .updateSiteRating(widget.histSite.name, rating);
                    });
                  },
                  borderColor: Colors.amber,
                  color: Colors.amber,
                  size: 60,
                )
                // Personal Rating

                // Text(
                //   personalRating != 0.0
                //       ? "You Rated: ${personalRating?.toStringAsFixed(0)} / 5"
                //       : "You Rated: N/A",
                //   style: GoogleFonts.rakkas(
                //     textStyle: const TextStyle(
                //         color: Color.fromARGB(255, 72, 52, 52), fontSize: 16),
                //   ),
                // ),
                ,
                //This Updates Immediately, but one step behind
                // Text(
                //     " (${widget.app_state.historicalSites.firstWhere((site) {
                //           if (site.name == widget.histSite.name) {
                //             print(site.name);
                //             return true;
                //           }
                //           return false;
                //         }).avgRating.toStringAsFixed(1)})",
                //     style: GoogleFonts.rakkas(
                //         textStyle: const TextStyle(
                //             color: Color.fromARGB(255, 72, 52, 52),
                //             fontSize: 16))),

                // This Updates After Each Reload
                Text(" (${widget.histSite.avgRating.toStringAsFixed(1)})",
                    style: GoogleFonts.rakkas(
                        textStyle: const TextStyle(
                            color: Color.fromARGB(255, 72, 52, 52),
                            fontSize: 16)))
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.histSite.blurbs.map((infoText) {
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      color: const Color.fromARGB(255, 250, 235, 215),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(infoText.title,
                                style: GoogleFonts.ultra(
                                    textStyle: const TextStyle(
                                        color: Color.fromARGB(255, 72, 52, 52),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))),
                            const SizedBox(height: 6),
                            Text(infoText.value,
                                style: GoogleFonts.rakkas(
                                    textStyle: const TextStyle(
                                        color: Color.fromARGB(255, 107, 79, 79),
                                        fontSize: 14))),
                            if (infoText.date != "")
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Date: ${infoText.date}",
                                  style: GoogleFonts.acme(
                                      textStyle: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 72, 52, 52),
                                          fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList()),
            ),
          ]),
        ));
  }
}
