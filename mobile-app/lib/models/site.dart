import 'package:app/constants/app_constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site.g.dart';

@JsonSerializable()
class Site {
  @JsonKey(required: true, name: '_id')
  final String id;

  @JsonKey(required: true)
  final double latitude;

  @JsonKey(required: true)
  final double longitude;

  @JsonKey(required: true, defaultValue: '')
  final String district;

  @JsonKey(required: true, defaultValue: '')
  final String country;

  @JsonKey(required: true, defaultValue: '')
  final String name;

  @JsonKey(required: false, defaultValue: '')
  final String description;

  @JsonKey(required: false, defaultValue: 0.0)
  double distance;

  @JsonKey(required: false, defaultValue: '')
  String userLocation = '';

  Site(this.name,
      {required this.id,
      required this.latitude,
      required this.longitude,
      required this.district,
      required this.country,
      required this.description,
      required this.distance});

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);

  String getLocation() {
    if (description == '') {
      return name;
    }
    return '$district $country';
  }

  String getName() {
    if (description == '') {
      return name;
    }
    return description;
  }

  String getUserLocation() {
    if (userLocation != '') {
      return userLocation;
    }
    return getName();
  }

  String getUserLocationName() {
    if (description == '') {
      return name;
    }
    return description;
  }

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  static String createTableStmt() =>
      'CREATE TABLE IF NOT EXISTS ${sitesDbName()}('
      '${dbId()} TEXT PRIMARY KEY, '
      '${dbCountry()} TEXT, '
      '${dbDistrict()} TEXT, '
      '${dbLongitude()} REAL, '
      '${dbLatitude()} REAL, '
      '${dbDescription()} TEXT, '
      '${dbSiteName()} TEXT )';

  static String dbCountry() => 'country';

  static String dbDescription() => 'description';

  static String dbDistance() => 'distance';

  static String dbDistrict() => 'district';

  static String dbId() => 'site_id';

  static String dbLatitude() => 'latitude';

  static String dbLongitude() => 'longitude';

  static String dbSiteName() => 'site_name';

  static String dropTableStmt() => 'DROP TABLE IF EXISTS ${sitesDbName()}';

  static Map<String, dynamic> fromDbMap(Map<String, dynamic> json) => {
        'name': json['${dbSiteName()}'] as String,
        'description': json['${dbDescription()}'] as String,
        '_id': json['${dbId()}'] as String,
        'country': json['${dbCountry()}'] as String,
        'district': json['${dbDistrict()}'] as String,
        'latitude': json['${dbLatitude()}'] as double,
        'longitude': json['${dbLongitude()}'] as double,
      };

  static List<Site> parseSites(dynamic jsonBody) {
    var sites = <Site>[];

    var jsonArray = jsonBody['sites'];
    for (var jsonElement in jsonArray) {
      try {
        var site = Site.fromJson(jsonElement);
        sites.add(site);
      } catch (e) {
        print('Error parsing sites : $e');
      }
    }

    sites.sort((siteA, siteB) =>
        siteA.getName().toLowerCase().compareTo(siteB.getName().toLowerCase()));

    return sites;
  }

  static String sitesDbName() => 'sites';

  static Map<String, dynamic> toDbMap(Site site) => {
        '${dbSiteName()}': site.name,
        '${dbDescription()}': site.description,
        '${dbId()}': site.id,
        '${dbCountry()}': site.country,
        '${dbDistrict()}': site.district,
        '${dbLatitude()}': site.latitude,
        '${dbLongitude()}': site.longitude
      };
}

@JsonSerializable()
class Sites {
  final List<Site> sites;

  Sites({
    required this.sites,
  });

  factory Sites.fromJson(Map<String, dynamic> json) => _$SitesFromJson(json);

  Map<String, dynamic> toJson() => _$SitesToJson(this);
}

extension ParseSite on Site {
  String getTopic(PollutantLevel pollutantLevel) {
    if (pollutantLevel == PollutantLevel.good) {
      return '$id-good'.trim().toLowerCase();
    } else if (pollutantLevel == PollutantLevel.moderate) {
      return '$id-moderate'.trim().toLowerCase();
    } else if (pollutantLevel == PollutantLevel.sensitive) {
      return '$id-sensitive'.trim().toLowerCase();
    } else if (pollutantLevel == PollutantLevel.unhealthy) {
      return '$id-unhealthy'.trim().toLowerCase();
    } else if (pollutantLevel == PollutantLevel.veryUnhealthy) {
      return '$id-very-unhealthy'.trim().toLowerCase();
    } else if (pollutantLevel == PollutantLevel.hazardous) {
      return '$id-hazardous'.trim().toLowerCase();
    }
    return '';
  }
}