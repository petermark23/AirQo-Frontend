import 'package:app/constants/config.dart';
import 'package:app/utils/web_view.dart';
import 'package:app/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAirQo extends StatefulWidget {
  const AboutAirQo({Key? key}) : super(key: key);

  @override
  _AboutAirQoState createState() => _AboutAirQoState();
}

class _AboutAirQoState extends State<AboutAirQo> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appTopBar(context, 'About'),
        body: Container(
            color: Config.appBodyColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 126,
                  ),
                  SvgPicture.asset(
                    'assets/icon/airqo_home.svg',
                    height: 52.86,
                    width: 76.91,
                    semanticsLabel: 'Home',
                  ),
                  const SizedBox(
                    height: 21.32,
                  ),
                  Text(
                    _packageInfo.appName,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Config.appColorBlack),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    '${_packageInfo.version}(${_packageInfo.buildNumber})',
                    style: TextStyle(fontSize: 16, color: Config.appColorBlack),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      openUrl(Config.termsUrl);
                    },
                    child: Text(
                      'Terms & Privacy Policy',
                      style:
                          TextStyle(fontSize: 16, color: Config.appColorBlue),
                    ),
                  ),
                  const SizedBox(
                    height: 90,
                  ),
                ],
              ),
            )));
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }
}