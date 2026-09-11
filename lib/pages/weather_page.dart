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
  // ponytail: Deliberately hardcoded list. Ceiling: Limited cities. Upgrade path: Use a City Geocoding API for global coverage.
  static const List<String> _availableCities = [
    'London', 'New York', 'Tokyo', 'Paris', 'Berlin', 'Sydney', 'Mumbai', 
    'Delhi', 'Beijing', 'Moscow', 'Dubai', 'Singapore', 'Los Angeles', 
    'Chicago', 'Toronto', 'Seoul', 'Bangkok', 'Istanbul', 'Rome', 'Madrid', 
    'Kolkata', 'Chennai', 'Bengaluru', 'Pune', 'Hyderabad', 'Ahmedabad', 'San Francisco'
  ];

  /// Fetch weather for the current city
  Future<void> _fetchWeather({String? city}) async {
    setState(() {
      _errorMessage = null; // Reset error state
    });

    try {
      // Get current city
      String cityName = city ?? await _weatherService.getCurrentCity();
      // Fetch weather data
      final weather = await _weatherService.getWeather(cityName);
      if (mounted) {
        setState(() {
          _weather = weather;
        });
      }
    } catch (e) {
      final cachedWeather = await _weatherService.getCachedWeather();
      if (mounted) {
        setState(() {
          if (cachedWeather != null) {
            _weather = cachedWeather;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offline: Showing last cached data')),
            );
          } else {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          }
        });
      }
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
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  // ponytail: Using Flutter's native Autocomplete. Ceiling: Simple string matching for fixed cities. Upgrade path: Integrate with City API.
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _availableCities.where((String city) =>
                          city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _fetchWeather(city: selection);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                _fetchWeather(city: controller.text);
                                focusNode.unfocus();
                              }
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) _fetchWeather(city: value);
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _fetchWeather(city: _weather?.cityName),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: _errorMessage != null
                                ? Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 18),
                                    textAlign: TextAlign.center,
                                  )
                                : _weather == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Lottie.asset('assets/loading.json', repeat: true), // Loading animation
                                          const SizedBox(height: 10),
                                          const Text("Fetching weather...", style: TextStyle(fontSize: 18)),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _weather!.cityName,
                                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10),
                                          Lottie.asset(
                                            getWeatherAnimation(_weather!.mainCondition),
                                            repeat: true,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${_weather!.temperature.round()}°C',
                                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            _weather!.mainCondition,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
