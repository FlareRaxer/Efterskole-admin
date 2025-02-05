import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efterskole_admin/utils.dart'; // Import utils for fetching school_id

class LineChartWidget extends StatefulWidget {
  const LineChartWidget({Key? key}) : super(key: key);

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  String? adminSchoolId;
  Map<String, int> chatsPerMonth = {};
  Map<String, int> usersPerMonth = {};
  bool isLoading = true;

  final List<String> months = [
    'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'
  ]; // Ordered months from August to July

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Fetch admin school ID
    adminSchoolId = await getCurrentAdminSchoolId();
    if (adminSchoolId != null) {
      await _fetchChatsPerMonth();
      await _fetchUsersPerMonth();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchChatsPerMonth() async {
    try {
      // Fetch chats where school_id matches the admin's school_id
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('school_id', isEqualTo: adminSchoolId)
          .get();

      for (var doc in chatSnapshot.docs) {
        Timestamp createdAt = doc['created_at'];
        DateTime date = createdAt.toDate();
        String month = months[date.month % 12 - 8]; // Mapping month to Aug-Jul cycle

        chatsPerMonth.update(month, (count) => count + 1, ifAbsent: () => 1);
      }
    } catch (e) {
      print('Error fetching chats: $e');
    }
  }

  Future<void> _fetchUsersPerMonth() async {
    try {
      // Fetch users where school_id matches the admin's school_id
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('school_id', isEqualTo: adminSchoolId)
          .get();

      for (var doc in userSnapshot.docs) {
        Timestamp createdAt = doc['created_at'];
        DateTime date = createdAt.toDate();
        String month = months[date.month % 12 - 8]; // Mapping month to Aug-Jul cycle

        usersPerMonth.update(month, (count) => count + 1, ifAbsent: () => 1);
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  List<FlSpot> _generateSpots(Map<String, int> data) {
    List<FlSpot> spots = [];

    for (int i = 0; i < months.length; i++) {
      final String month = months[i];
      spots.add(FlSpot(i.toDouble(), data[month]?.toDouble() ?? 0));
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
                      reservedSize: 28, // Adds space below the X-axis labels
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0), // Add space between chart and month labels
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
                    spots: _generateSpots(chatsPerMonth),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    ),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.secondary,
                    tooltipPadding: const EdgeInsets.all(8.0),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            '${touchedSpot.y.toInt()} samtaler',
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