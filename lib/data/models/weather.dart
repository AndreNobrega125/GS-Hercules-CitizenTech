/// Um dia de clima (previsão ou histórico).
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.rainMm,
  });

  final DateTime date;
  final double? tempMax;
  final double? tempMin;
  final double? rainMm;

  /// Converte o bloco `daily` do Open-Meteo em uma lista de dias.
  static List<DailyWeather> listFromDaily(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    List<dynamic>? col(String k) => daily[k] as List<dynamic>?;
    double? at(List<dynamic>? l, int i) =>
        l == null ? null : (l[i] as num?)?.toDouble();

    final max = col('temperature_2m_max');
    final min = col('temperature_2m_min');
    final rain = col('precipitation_sum');
    return [
      for (var i = 0; i < times.length; i++)
        DailyWeather(
          date: DateTime.parse(times[i]),
          tempMax: at(max, i),
          tempMin: at(min, i),
          rainMm: at(rain, i),
        ),
    ];
  }
}
