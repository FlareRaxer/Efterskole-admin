import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efterskole_admin/utils.dart'; // Import utils for fetching school_id

class BlueLineChartWidget extends StatefulWidget {
  const BlueLineChartWidget({Key? key}) : super(key: key);

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<BlueLineChartWidget> {
  String? adminSchoolId;
  Map<String, int> usersPerMonth = {};
  bool isLoading = true;

  final List<String> months = [
    'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'
  ]; // Ordered months from August to July

  List<double> actualYValues = []; // List to store actual y-values

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Fetch admin school ID
    adminSchoolId = await getCurrentAdminSchoolId();
    if (adminSchoolId != null) {
      await _fetchUsersPerMonth();
    }
    setState(() {
      isLoading = false;
    });
  }

  // Adjust the school year range as needed
  int _startYear = 2024;
  int _endYear = 2025;

  Future<void> _fetchUsersPerMonth() async {
    try {
      // Fetch users where school_id matches the admin's school_id
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('school_id', isEqualTo: adminSchoolId)
          .where('is_mentor', isEqualTo: false)
          .get();

      print('Number of users fetched: ${userSnapshot.docs.length}');

      for (var doc in userSnapshot.docs) {
        // Debugging: Print user details
        print('User: ${doc['full_name']},  isMentor: ${doc['is_mentor']}');
        Timestamp createdAt = doc['created_at'];
        DateTime date = createdAt.toDate();

        // Check if the date falls within the specified school year range
        if ((date.month >= 8 && date.year == _startYear) || (date.month < 8 && date.year == _endYear)) {
          // Corrected month mapping
          int monthIndex = (date.month - 8) % 12;
          if (monthIndex < 0) monthIndex += 12;
          String month = months[monthIndex];

          usersPerMonth.update(month, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  List<FlSpot> _generateSpots(Map<String, int> data) {
    List<FlSpot> spots = [];
    actualYValues = []; // Reset the list for fresh data

    for (int i = 0; i < months.length; i++) {
      final String month = months[i];
      double yValue = data[month]?.toDouble() ?? 0;

      actualYValues.add(yValue); // Store the actual y-value

      // Clamp y-value to maxY (50)
      double clampedY = yValue > 50 ? 50 : yValue;

      spots.add(FlSpot(i.toDouble(), clampedY));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth < 900; 
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(6.0), // Increased padding for spacing
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.white,
                minY: 0,
                maxY: 50,
                gridData: const FlGridData(
                  show: true,
                  horizontalInterval: 5,
                  drawVerticalLine: false,
                  drawHorizontalLine: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: isSmallScreen ? 3 : 1, // viser hver 3. måned på små skærme - viser stadig hver måned på store skærme
                      reservedSize: 32, // Adds space below the X-axis labels
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0), // Add space between chart and month labels
                            child: Text(
                              months[index],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 40, // Adds space between Y-axis labels and the chart
                      getTitlesWidget: (value, _) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0), // Add spacing between number and chart
                          child: Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(usersPerMonth),
                    isCurved: true,
                    color: Color(0xFF66CCCC),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF66CCCC).withOpacity(0.5),
                          Color(0xFF66CCCC).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                    barWidth: 4,
                  ),
                ],
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.secondary,
                    tooltipPadding: const EdgeInsets.all(8.0),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        int index = spot.spotIndex; // Get the index of the spot
                        double actualY = actualYValues[index]; // Retrieve the actual y-value

                        return LineTooltipItem(
                          '${actualY.toString()} brugere', // Display the actual y-value
                          Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black) ?? TextStyle(color: Colors.black),

                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          );
  }
}