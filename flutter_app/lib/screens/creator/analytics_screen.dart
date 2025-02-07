import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show max;
import '../../models/bit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Bit? selectedBit;
  List<Bit> allBits = [];
  Map<String, dynamic>? selectedBitAnalytics;
  Map<String, dynamic>? overallAnalytics;
  List<Map<String, dynamic>>? timeBasedReactions;
  bool isLoading = true;

  static const reactionColors = {
    'rofl': Colors.green,
    'smirk': Colors.blue,
    'eyeroll': Colors.orange,
    'vomit': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Load bits
      final snapshot =
          await FirebaseFirestore.instance.collection('bits').get();

      allBits = snapshot.docs.map((doc) => Bit.fromFirestore(doc)).toList();

      // Load overall analytics
      await _loadOverallAnalytics();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _loadOverallAnalytics() async {
    int totalViews = 0;
    int totalReactions = 0;
    Map<String, int> reactionCounts = {
      'rofl': 0,
      'smirk': 0,
      'eyeroll': 0,
      'vomit': 0,
    };

    // Get analytics for all bits
    for (final bit in allBits) {
      final doc = await FirebaseFirestore.instance
          .collection('bits')
          .doc(bit.id)
          .collection('analytics')
          .doc('stats')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        totalViews += (data['viewCount'] as num?)?.toInt() ?? 0;
        totalReactions += (data['totalReactions'] as num?)?.toInt() ?? 0;

        final bitReactionCounts =
            data['reactionCounts'] as Map<String, dynamic>?;
        if (bitReactionCounts != null) {
          for (final type in reactionCounts.keys) {
            reactionCounts[type] = (reactionCounts[type] ?? 0) +
                ((bitReactionCounts[type] as num?)?.toInt() ?? 0);
          }
        }
      }
    }

    setState(() {
      overallAnalytics = {
        'viewCount': totalViews,
        'totalReactions': totalReactions,
        'reactionCounts': reactionCounts,
      };
    });
  }

  Future<void> _loadBitAnalytics(String bitId) async {
    try {
      final statsDoc = await FirebaseFirestore.instance
          .collection('bits')
          .doc(bitId)
          .collection('analytics')
          .doc('stats')
          .get();

      if (statsDoc.exists) {
        setState(() {
          selectedBitAnalytics = statsDoc.data();
        });
      }

      // Load time-based reactions
      final reactionsSnapshot = await FirebaseFirestore.instance
          .collection('bits')
          .doc(bitId)
          .collection('reactions')
          .orderBy('timestamp')
          .get();

      if (reactionsSnapshot.docs.isNotEmpty) {
        final reactions =
            reactionsSnapshot.docs.map((doc) => doc.data()).toList();
        _processTimeBasedReactions(reactions);
      } else {
        setState(() {
          timeBasedReactions = null;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  void _processTimeBasedReactions(List<Map<String, dynamic>> reactions) {
    // Group reactions into 5-second intervals
    final intervalData = <int, Map<String, int>>{};

    for (final reaction in reactions) {
      final timestamp = (reaction['timestamp'] as num).toDouble();
      final interval =
          (timestamp / 5).floor() * 5; // Round to nearest 5 seconds

      intervalData.putIfAbsent(
          interval,
          () => {
                'rofl': 0,
                'smirk': 0,
                'eyeroll': 0,
                'vomit': 0,
              });

      intervalData[interval]![reaction['type'] as String] =
          (intervalData[interval]![reaction['type'] as String] ?? 0) + 1;
    }

    // Convert to list and sort by interval
    final processedData = intervalData.entries
        .map((entry) => {
              'interval': entry.key,
              ...entry.value,
            })
        .toList()
      ..sort((a, b) => (a['interval'] as int).compareTo(b['interval'] as int));

    setState(() {
      timeBasedReactions = processedData;
    });
  }

  Widget _buildPieChart(Map<String, int> reactionCounts) {
    final total = reactionCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return const Center(child: Text('No reactions yet'));
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: reactionCounts['rofl']!.toDouble(),
              title:
                  '🤣\n${((reactionCounts['rofl']! / total) * 100).toStringAsFixed(1)}%',
              radius: 100,
            ),
            PieChartSectionData(
              color: Colors.blue,
              value: reactionCounts['smirk']!.toDouble(),
              title:
                  '😏\n${((reactionCounts['smirk']! / total) * 100).toStringAsFixed(1)}%',
              radius: 100,
            ),
            PieChartSectionData(
              color: Colors.orange,
              value: reactionCounts['eyeroll']!.toDouble(),
              title:
                  '🙄\n${((reactionCounts['eyeroll']! / total) * 100).toStringAsFixed(1)}%',
              radius: 100,
            ),
            PieChartSectionData(
              color: Colors.red,
              value: reactionCounts['vomit']!.toDouble(),
              title:
                  '🤮\n${((reactionCounts['vomit']! / total) * 100).toStringAsFixed(1)}%',
              radius: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBasedBarChart() {
    if (timeBasedReactions == null || timeBasedReactions!.isEmpty) {
      return const Center(child: Text('No reaction data available'));
    }

    // Find total height for each interval
    final maxY = timeBasedReactions!.map((data) {
      return reactionColors.keys
          .map((type) => data[type] as int)
          .reduce((a, b) => a + b)
          .toDouble();
    }).reduce(max);

    final padding = (maxY * 0.07).ceil();
    final adjustedMaxY = (((maxY + padding) / 3).ceil() * 3).toDouble();

    final increment = adjustedMaxY <= 20
        ? 1
        : adjustedMaxY <= 50
            ? 5
            : adjustedMaxY <= 100
                ? 10
                : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: reactionColors.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: entry.value,
                ),
                const SizedBox(width: 4),
                Text(entry.key),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Scrollable chart
        SizedBox(
          height: 300,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(right: 32),
              width: timeBasedReactions!.length * 40.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: adjustedMaxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = timeBasedReactions![groupIndex];
                        final type = reactionColors.keys.elementAt(rodIndex);
                        return BarTooltipItem(
                          '${type}: ${data[type]}\nat ${data['interval']}s',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                      axisNameSize: 24, // Add padding at top
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 ||
                              value >= timeBasedReactions!.length) {
                            return const SizedBox.shrink();
                          }
                          final data = timeBasedReactions![value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${data['interval']}s',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45, // Increased more
                        interval: increment.toDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0');
                          if (value == adjustedMaxY) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12), // Add padding for top number
                              child: Text(adjustedMaxY.toInt().toString()),
                            );
                          }
                          if (value % increment == 0) {
                            return Text(value.toInt().toString());
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        increment.toDouble(), // Match grid to increments
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(),
                      left: BorderSide(),
                    ),
                  ),
                  barGroups: List.generate(timeBasedReactions!.length, (index) {
                    final data = timeBasedReactions![index];
                    double cumulative = 0;

                    return BarChartGroupData(
                      x: index,
                      groupVertically: true, // Stack the bars
                      barRods: reactionColors.entries.map((entry) {
                        final type = entry.key;
                        final color = entry.value;
                        final value = (data[type] as int).toDouble();
                        final rod = BarChartRodData(
                          fromY: cumulative,
                          toY: cumulative + value,
                          color: color,
                          width: 25,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        );
                        cumulative += value;
                        return rod;
                      }).toList(),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bit selector
                  DropdownButtonFormField<Bit?>(
                    value: selectedBit,
                    decoration: const InputDecoration(
                      labelText: 'Select a Bit (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Bits Combined'),
                      ),
                      ...allBits.map((bit) {
                        return DropdownMenuItem(
                          value: bit,
                          child: Text(bit.title),
                        );
                      }).toList(),
                    ],
                    onChanged: (bit) {
                      setState(() {
                        selectedBit = bit;
                        selectedBitAnalytics = null;
                        timeBasedReactions = null;
                      });
                      if (bit != null) {
                        _loadBitAnalytics(bit.id);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    selectedBit?.title ?? 'Overall Analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Analytics cards
                  if (selectedBit == null && overallAnalytics != null ||
                      selectedBit != null && selectedBitAnalytics != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticCard(
                            'Total Views',
                            (selectedBit == null
                                        ? overallAnalytics!['viewCount']
                                        : selectedBitAnalytics!['viewCount'])
                                    ?.toString() ??
                                '0',
                            Icons.visibility,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnalyticCard(
                            'Total Reactions',
                            (selectedBit == null
                                        ? overallAnalytics!['totalReactions']
                                        : selectedBitAnalytics![
                                            'totalReactions'])
                                    ?.toString() ??
                                '0',
                            Icons.emoji_emotions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Reaction Distribution',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart(
                      Map<String, int>.from(
                        selectedBit == null
                            ? overallAnalytics!['reactionCounts'] ?? {}
                            : selectedBitAnalytics!['reactionCounts'] ?? {},
                      ),
                    ),
                    if (selectedBit != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Reactions Over Time',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeBasedBarChart(),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
