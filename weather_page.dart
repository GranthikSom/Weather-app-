import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/weather_model.dart';
import 'package:flutter_application_2/services/weather_service.dart';
import 'package:lottie/lottie.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // API key
  final _weatherService = WeatherService('0e9e2f2b6fc97d6150b277150750a79c');
  Weather? _weather;
  String? _errorMessage;

  /// Fetch weather for the current city
  Future<void> _fetchWeather() async {
    setState(() {
      _errorMessage = null; // Reset error state
    });

    try {
      // Get current city
      String cityName = await _weatherService.getCurrentCity();
      print("Retrieved city: $cityName"); 
      // Fetch weather data
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "$e";
      });
    }
  }

  /// Get animation based on weather condition
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json'; // Default animation

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/thunder.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json'; // Default for unknown conditions
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather(); // Call it correctly inside initState
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Full-screen background animation
        Positioned.fill(
          child: Lottie.asset(
            "assets/world.json",  // Path to JSON animation
            fit: BoxFit.cover,
          ),
        ),
        
        // Foreground content (Weather details)
        Center(
          child: _errorMessage != null
              ? Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                )
              : _weather == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/loading.json', repeat: true), // Loading animation
                        const SizedBox(height: 10),
                        Text("Fetching weather...", style: TextStyle(fontSize: 18)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weather!.cityName,
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Lottie.asset(
                          getWeatherAnimation(_weather!.mainCondition ?? 'clear'),
                          repeat: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_weather!.temperature.round()}°C',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _weather!.mainCondition ?? "Unknown",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
        ),
      ],
    ),
  );
}
}