import 'package:app/constants/app_constants.dart';
import 'package:app/on_boarding/onBoarding_page.dart';
import 'package:app/screens/map_page.dart';
import 'package:app/screens/profile_view.dart';
import 'package:app/screens/resources_page.dart';
import 'package:app/screens/settings_page.dart';
import 'package:app/screens/settings_view.dart';
import 'package:app/screens/share_picture.dart';
import 'package:app/services/local_storage.dart';
import 'package:app/services/rest_api.dart';
import 'package:app/utils/dialogs.dart';
import 'package:app/utils/share.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_view.dart';
import 'help_page.dart';
import 'maps_view.dart';
import 'my_places_view.dart';

class HomePage extends StatefulWidget {
  final String title = 'AirQo';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final PageController _pageCtrl = PageController(initialPage: 0);
  String title = '${AppConfig.name}';
  bool showAddPlace = true;
  DateTime? exitTime;

  double selectedPage = 0;
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = <Widget>[
    DashboardView(),
    const MapView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.appBodyColor,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
            canvasColor: ColorConstants.appBodyColor,
            primaryColor: Colors.black,
            textTheme: Theme.of(context)
                .textTheme
                .copyWith(caption: const TextStyle(color: Colors.black))),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: ColorConstants.appColorBlue,
          unselectedItemColor: ColorConstants.inactiveColor,
          elevation: 0.0,
          backgroundColor: ColorConstants.appBodyColor,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  Widget builds(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          // height: 50,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Spacer(
                flex: 1,
              ),
              IconButton(
                // iconSize: 30.0,
                // padding: const EdgeInsets.only(left: 28.0),
                icon: Icon(Icons.home_outlined,
                    color: selectedPage == 0
                        ? ColorConstants.appColor
                        : ColorConstants.inactiveColor),
                splashColor: ColorConstants.appColor,
                onPressed: () {
                  setState(() {
                    _pageCtrl.jumpToPage(0);
                  });
                },
              ),
              const Spacer(
                flex: 1,
              ),
              IconButton(
                // iconSize: 30.0,
                // padding: const EdgeInsets.only(left: 28.0),
                icon: Icon(Icons.favorite,
                    color: selectedPage == 1
                        ? ColorConstants.appColor
                        : ColorConstants.inactiveColor),
                splashColor: ColorConstants.appColor,
                onPressed: () {
                  setState(() {
                    _pageCtrl.jumpToPage(1);
                  });
                },
              ),
              const Spacer(
                flex: 3,
              ),
              IconButton(
                // iconSize: 30.0,
                // padding: const EdgeInsets.only(right: 28.0),
                icon: Icon(Icons.library_books_outlined,
                    color: selectedPage == 2
                        ? ColorConstants.appColor
                        : ColorConstants.inactiveColor),
                splashColor: ColorConstants.appColor,
                onPressed: () {
                  setState(() {
                    _pageCtrl.jumpToPage(2);
                  });
                },
              ),
              const Spacer(
                flex: 1,
              ),
              IconButton(
                // iconSize: 30.0,
                // padding: const EdgeInsets.only(right: 28.0),
                icon: Icon(Icons.settings,
                    color: selectedPage == 3
                        ? ColorConstants.appColor
                        : ColorConstants.inactiveColor),
                splashColor: ColorConstants.appColor,
                onPressed: () {
                  setState(() {
                    _pageCtrl.jumpToPage(3);
                  });
                },
              ),
              const Spacer(
                flex: 1,
              ),
            ],
          ),
        ),
      ),
      body: WillPopScope(
        onWillPop: onWillPop,
        child: PageView(
          controller: _pageCtrl,
          onPageChanged: switchTitle,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            DashboardView(),
            MyPlacesView(),
            ResourcesPage(),
            SettingsView(),
          ],
        ),
      ),
      floatingActionButton: Container(
        // height: 60.0,
        // width: 60.0,
        child: FittedBox(
          child: FloatingActionButton(
              mini: false,
              backgroundColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MapPage();
                }));
              },
              child: FaIcon(
                FontAwesomeIcons.map,
                color: ColorConstants.appColor,
              )
              // child: Image.asset(
              //   'assets/images/world-map.png',
              //   // height: 10,
              //   // width: 10,
              // ),
              // child: const Icon(
              //   Icons.public_sharp,
              //   color: Colors.white,
              // ),
              // elevation: 5.0,
              ),
        ),
      ),
    );
  }

  Future<void> initialize() async {
    _getLatestMeasurements();
    _getSites();
  }

  @override
  void initState() {
    // _displayOnBoarding();
    initialize();
    super.initState();
  }

  void navigateToMenuItem(dynamic position) {
    var menuItem = position.toString();

    if (menuItem.trim().toLowerCase() == 'share') {
      shareApp();
    } else if (menuItem.trim().toLowerCase() == 'aqi index') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const HelpPage(
            initialIndex: 0,
          ),
          fullscreenDialog: true,
        ),
      );
    } else if (menuItem.trim().toLowerCase() == 'camera') {
      takePhoto();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return SettingsPage();
      }));
    }
  }

  Future<bool> onWillPop() {
    var now = DateTime.now();

    if (exitTime == null ||
        now.difference(exitTime!) > const Duration(seconds: 2)) {
      exitTime = now;

      showSnackBar(context, 'Tap again to exit !');
      return Future.value(false);
    }
    return Future.value(true);
  }

  void switchTitle(tile) {
    switch (tile) {
      case 0:
        setState(() {
          title = '${AppConfig.name}';
          showAddPlace = true;
          selectedPage = 0;
        });
        break;
      case 1:
        setState(() {
          title = 'MyPlaces';
          showAddPlace = false;
          selectedPage = 1;
        });
        break;
      case 2:
        setState(() {
          title = 'News Feed';
          showAddPlace = false;
          selectedPage = 2;
        });
        break;
      case 3:
        setState(() {
          title = 'Settings';
          showAddPlace = false;
          selectedPage = 3;
        });
        break;
      default:
        setState(() {
          title = '${AppConfig.name}';
          showAddPlace = true;
          selectedPage = 0;
        });
        break;
    }
  }

  Future<void> takePhoto() async {
    // Obtain a list of the available cameras on the phone.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    if (cameras.isEmpty) {
      await showSnackBar(context, 'Could not open AQI camera');
      return;
    }
    final firstCamera = cameras.first;

    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return TakePicture(
        camera: firstCamera,
      );
    }));
  }

  Future<void> _displayOnBoarding() async {
    var prefs = await SharedPreferences.getInstance();
    var isFirstUse = prefs.getBool(PrefConstant.firstUse) ?? true;

    if (isFirstUse) {
      await Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) {
        return OnBoardingPage();
      }), (r) => false);
    }
  }

  Future<void> _getHistoricalMeasurements() async {
    await AirqoApiClient(context)
        .fetchHistoricalMeasurements()
        .then((value) => {
              if (value.isNotEmpty)
                {DBHelper().insertHistoricalMeasurements(value)}
            });
  }

  void _getLatestMeasurements() async {
    await AirqoApiClient(context).fetchLatestMeasurements().then((value) => {
          if (value.isNotEmpty) {DBHelper().insertLatestMeasurements(value)}
        });
  }

  void _getSites() async {
    await AirqoApiClient(context).fetchSites().then((value) => {
          if (value.isNotEmpty) {DBHelper().insertSites(value)}
        });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
