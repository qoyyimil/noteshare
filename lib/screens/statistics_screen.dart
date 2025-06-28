import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/services/firestore_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Map<String, double> _calculateAxisDetails(double maxDataValue) {
    if (maxDataValue <= 0) {
      return {'maxY': 10.0, 'interval': 2.0};
    } else if (maxDataValue <= 10) {
      return {'maxY': (maxDataValue.ceilToDouble() + 2), 'interval': 2.0};
    } else if (maxDataValue <= 50) {
      return {'maxY': ( (maxDataValue / 5).ceil() * 5.0) + 5, 'interval': 5.0};
    } else if (maxDataValue <= 100) {
      return {'maxY': ( (maxDataValue / 10).ceil() * 10.0) + 10, 'interval': 10.0};
    } else {
       double interval = pow(10, (log(maxDataValue) / log(10)).floor()).toDouble();
       return {'maxY': ((maxDataValue / interval).ceil() * interval) + interval, 'interval': interval / 2};
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Statistics", style: GoogleFonts.lato()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'Notes Stats'),
            Tab(text: 'Audience Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotesStatsView(),
          _buildAudienceStatsView(),
        ],
      ),
    );
  }

  Widget _buildNotesStatsView() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firestoreService.getNotesAndStatsForUser(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!['dailyStats'].isEmpty) {
          return const Center(child: Text("No data to display."));
        }

        final stats = snapshot.data!;
        final int totalLikes = stats['totalLikes'];
        final int totalReads = stats['totalReads'];
        final Map<DateTime, Map<String, int>> dailyStats = stats['dailyStats'];

        List<FlSpot> readsSpots = [];
        List<FlSpot> likesSpots = [];

        final sortedEntries = dailyStats.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        double maxReadsValue = 0;
        double maxLikesValue = 0;

        for (var entry in sortedEntries) {
          final readValue = entry.value['reads']!.toDouble();
          final likeValue = entry.value['likes']!.toDouble();
          
          if (readValue > maxReadsValue) maxReadsValue = readValue;
          if (likeValue > maxLikesValue) maxLikesValue = likeValue;

          readsSpots.add(FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), readValue));
          likesSpots.add(FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), likeValue));
        }
        
        final readsAxisDetails = _calculateAxisDetails(maxReadsValue);
        final likesAxisDetails = _calculateAxisDetails(maxLikesValue);


        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Performance Summary", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatsCard("Total Likes", totalLikes.toString()),
                  _buildStatsCard("Total Reads", totalReads.toString()),
                ],
              ),
              
              const SizedBox(height: 32),
              Text("Daily Views", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildChart(
                spots: readsSpots, 
                color: Colors.blue, 
                maxY: readsAxisDetails['maxY']!, 
                intervalY: readsAxisDetails['interval']!
              ),

              const SizedBox(height: 32),
              Text("Daily Likes", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildChart(
                spots: likesSpots, 
                color: Colors.pink, 
                maxY: likesAxisDetails['maxY']!, 
                intervalY: likesAxisDetails['interval']!
              ),

            ],
          ),
        );
      },
    );
  }

  // --- PERBAIKAN: Mengganti AspectRatio dengan SizedBox ---
  Widget _buildChart({required List<FlSpot> spots, required Color color, required double maxY, required double intervalY}) {
     return SizedBox(
      height: 250, // Memberikan tinggi tetap pada grafik
      child: LineChart(
        LineChartData(
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 40,
                interval: intervalY,
              )
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: spots.length > 5 ? Duration(days: 5).inMilliseconds.toDouble() : Duration(days: 1).inMilliseconds.toDouble(),
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.lato(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceStatsView() {
    return StreamBuilder<int>(
      stream: _firestoreService.getFollowersCount(widget.userId),
      builder: (context, followersSnapshot) {
        return StreamBuilder<int>(
          stream: _firestoreService.getFollowingCount(widget.userId),
          builder: (context, followingSnapshot) {
            if (followersSnapshot.connectionState == ConnectionState.waiting || followingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final followers = followersSnapshot.data ?? 0;
            final following = followingSnapshot.data ?? 0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Audience Overview", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildStatsCard("Followers", followers.toString()),
                    const SizedBox(height: 16),
                    _buildStatsCard("Following", following.toString()),
                     const SizedBox(height: 32),
                    Text("More audience analytics coming soon!", style: GoogleFonts.lato(color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
