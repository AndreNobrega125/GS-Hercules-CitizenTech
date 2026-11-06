/// Leitura horária de material particulado (µg/m³).
class AirReading {
  const AirReading({required this.time, this.pm25, this.pm10});

  final DateTime time;
  final double? pm25;
  final double? pm10;

  static List<AirReading> listFromJson(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final pm25 = hourly['pm2_5'] as List<dynamic>;
    final pm10 = hourly['pm10'] as List<dynamic>;
    return [
      for (var i = 0; i < times.length; i++)
        AirReading(
          time: DateTime.parse(times[i]),
          pm25: (pm25[i] as num?)?.toDouble(),
          pm10: (pm10[i] as num?)?.toDouble(),
        ),
    ];
  }
}
