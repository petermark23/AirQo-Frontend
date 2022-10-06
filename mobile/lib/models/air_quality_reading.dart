import 'package:app/models/models.dart';
import 'package:app_repository/app_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

import '../constants/config.dart';

part 'air_quality_reading.g.dart';

@JsonSerializable()
@HiveType(typeId: 50, adapterName: 'AirQualityReadingAdapter')
class AirQualityReading extends HiveObject {
  AirQualityReading({
    required this.referenceSite,
    required this.source,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.name,
    required this.location,
    required this.region,
    required this.dateTime,
    required this.pm2_5,
    required this.pm10,
    required this.distanceToReferenceSite,
    required this.placeId,
    required this.airQuality,
  });

  factory AirQualityReading.fromJson(Map<String, dynamic> json) =>
      _$AirQualityReadingFromJson(json);

  factory AirQualityReading.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;

    final referenceSite =
        data.containsKey('referenceSite') ? data['referenceSite'] : '';
    final source = data.containsKey('source') ? data['source'] : '';
    final latitude = data.containsKey('latitude') ? data['latitude'] : 0.0;
    final longitude = data.containsKey('longitude') ? data['longitude'] : 0.0;
    final pm2_5 = data.containsKey('pm2_5') ? data['pm2_5'] : 0.0;
    final pm10 = data.containsKey('pm10') ? data['pm10'] : 0.0;
    final distanceToReferenceSite = data.containsKey('distanceToReferenceSite')
        ? data['distanceToReferenceSite']
        : 0.0;
    final country = data.containsKey('country') ? data['country'] : '';
    final name = data.containsKey('name') ? data['name'] : '';
    final placeId = data.containsKey('placeId') ? data['placeId'] : '';
    final airQuality = data.containsKey('airQuality') ? data['airQuality'] : '';
    final location = data.containsKey('location') ? data['location'] : '';
    final region = data.containsKey('region') ? data['region'] : '';
    final dateTime =
        data.containsKey('dateTime') ? data['dateTime'] : DateTime.now();

    return AirQualityReading(
      referenceSite: referenceSite is String ? referenceSite : '',
      source: source is String ? source : '',
      latitude: latitude is double ? latitude : 0.0,
      longitude: longitude is double ? longitude : 0.0,
      country: country is String ? country : '',
      name: name is String ? name : '',
      location: location is String ? location : '',
      region: const RegionConverter().fromJson(region is String ? region : ''),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (dateTime is DateTime ? dateTime : DateTime.now())
            .millisecondsSinceEpoch,
      ),
      pm2_5: pm2_5 is double ? pm2_5 : 0.0,
      pm10: pm10 is double ? pm10 : 0.0,
      distanceToReferenceSite:
          distanceToReferenceSite is double ? distanceToReferenceSite : 0.0,
      placeId: placeId is String ? placeId : '',
      airQuality: const AirQualityConverter()
          .fromJson(airQuality is String ? airQuality : ''),
    );
  }

  factory AirQualityReading.fromSiteReading(SiteReading siteReading) {
    return AirQualityReading(
      referenceSite: siteReading.siteId,
      latitude: siteReading.latitude,
      longitude: siteReading.longitude,
      country: siteReading.country,
      name: siteReading.name,
      location: siteReading.location,
      region: Region.fromString(siteReading.region),
      source: siteReading.source,
      dateTime: siteReading.dateTime,
      pm2_5: siteReading.pm2_5,
      pm10: siteReading.pm10,
      distanceToReferenceSite: 0.0,
      placeId: siteReading.siteId,
      airQuality:
          AirQuality.fromPollutantValue(siteReading.pm2_5, Pollutant.pm2_5),
    );
  }

  factory AirQualityReading.fromFavouritePlace(FavouritePlace favouritePlace) {
    return AirQualityReading(
      referenceSite: favouritePlace.referenceSite,
      latitude: favouritePlace.latitude,
      longitude: favouritePlace.longitude,
      country: favouritePlace.location,
      name: favouritePlace.name,
      location: favouritePlace.location,
      region: Region.fromString(''),
      source: favouritePlace.location,
      dateTime: DateTime.now(),
      pm2_5: 0.0,
      pm10: 0.0,
      distanceToReferenceSite: 0.0,
      placeId: favouritePlace.placeId,
      airQuality: AirQuality.fromPollutantValue(0.0, Pollutant.pm2_5),
    );
  }

  factory AirQualityReading.duplicate(AirQualityReading airQualityReading) {
    return AirQualityReading(
      referenceSite: airQualityReading.referenceSite,
      source: airQualityReading.referenceSite,
      latitude: airQualityReading.latitude,
      longitude: airQualityReading.longitude,
      country: airQualityReading.country,
      name: airQualityReading.name,
      location: airQualityReading.location,
      region: airQualityReading.region,
      dateTime: airQualityReading.dateTime,
      pm2_5: airQualityReading.pm2_5,
      pm10: airQualityReading.pm10,
      distanceToReferenceSite: airQualityReading.distanceToReferenceSite,
      placeId: airQualityReading.placeId,
      airQuality: airQualityReading.airQuality,
    );
  }

  AirQualityReading copyWith({
    double? distanceToReferenceSite,
    String? placeId,
    String? name,
    String? location,
    String? referenceSite,
    double? latitude,
    double? longitude,
    DateTime? dateTime,
    double? pm2_5,
    double? pm10,
    AirQuality? airQuality,
  }) {
    return AirQualityReading(
      referenceSite: referenceSite ?? this.referenceSite,
      source: source,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country,
      name: name ?? this.name,
      location: location ?? this.location,
      region: region,
      dateTime: dateTime ?? this.dateTime,
      pm2_5: pm2_5 ?? this.pm2_5,
      pm10: pm10 ?? this.pm10,
      airQuality: airQuality ?? this.airQuality,
      distanceToReferenceSite:
          distanceToReferenceSite ?? this.distanceToReferenceSite,
      placeId: placeId ?? this.placeId,
    );
  }

  AirQualityReading populateFavouritePlace(FavouritePlace favouritePlace) {
    return AirQualityReading.duplicate(
      AirQualityReading(
        placeId: favouritePlace.placeId,
        latitude: favouritePlace.latitude,
        longitude: favouritePlace.longitude,
        name: favouritePlace.name,
        location: favouritePlace.location,
        referenceSite: referenceSite,
        source: source,
        country: country,
        region: region,
        dateTime: dateTime,
        pm2_5: pm2_5,
        pm10: pm10,
        distanceToReferenceSite: distanceToReferenceSite,
        airQuality: airQuality,
      ),
    );
  }

  @HiveField(0)
  @JsonKey(defaultValue: '')
  final String referenceSite;

  @HiveField(1)
  @JsonKey(defaultValue: 0.0)
  final double latitude;

  @HiveField(2)
  @JsonKey(defaultValue: 0.0)
  final double longitude;

  @HiveField(3)
  @JsonKey(defaultValue: '')
  final String country;

  @HiveField(4)
  @JsonKey(defaultValue: '')
  final String name;

  @HiveField(5)
  @JsonKey(defaultValue: '')
  final String source;

  @HiveField(6)
  @JsonKey(defaultValue: '')
  final String location;

  @HiveField(7)
  @RegionConverter()
  final Region region;

  @HiveField(8)
  final DateTime dateTime;

  @HiveField(9)
  @JsonKey(defaultValue: 0.0)
  final double pm2_5;

  @HiveField(10)
  @JsonKey(defaultValue: 0.0)
  final double pm10;

  @HiveField(11)
  @JsonKey(defaultValue: 0.0)
  final double distanceToReferenceSite;

  @HiveField(12)
  @JsonKey(defaultValue: '')
  final String placeId;

  @HiveField(13)
  @AirQualityConverter()
  final AirQuality airQuality;

  Map<String, dynamic> toJson() => _$AirQualityReadingToJson(this);
}

List<AirQualityReading> sortAirQualityReadingsByDistance(
  List<AirQualityReading> airQualityReadings,
) {
  airQualityReadings.sort(
    (x, y) {
      return x.distanceToReferenceSite.compareTo(y.distanceToReferenceSite);
    },
  );

  return airQualityReadings;
}

List<AirQualityReading> filterNearestLocations(
  List<AirQualityReading> airQualityReadings,
) {
  airQualityReadings = airQualityReadings
      .where(
        (element) => element.distanceToReferenceSite <= Config.searchRadius,
      )
      .toList();
  airQualityReadings = sortAirQualityReadingsByDistance(airQualityReadings);

  return airQualityReadings;
}
