import 'package:flutter/material.dart';

/// A simple usage chart for displaying telecom usage data
/// This is a placeholder for a real chart implementation
/// In a real app, you would use a chart library like fl_chart or charts_flutter
class UsageChart extends StatelessWidget {
  const UsageChart({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a simplified placeholder implementation
    // In a real app, you'd use a proper chart library
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            'Last 6 Months Usage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Jan', 0.3, Colors.blue, constraints.maxHeight),
                  _buildBar('Feb', 0.5, Colors.blue, constraints.maxHeight),
                  _buildBar('Mar', 0.7, Colors.blue, constraints.maxHeight),
                  _buildBar('Apr', 0.4, Colors.blue, constraints.maxHeight),
                  _buildBar('May', 0.8, Colors.blue, constraints.maxHeight),
                  _buildBar('Jun', 0.6, Colors.purple, constraints.maxHeight),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Data', Colors.blue),
            _buildLegendItem('Voice', Colors.green),
            _buildLegendItem('SMS', Colors.amber),
            _buildLegendItem('Current', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildBar(String label, double height, Color color, double maxHeight) {
    final barHeight = maxHeight * 0.65 * height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
