// lib/widgets/stop_list_item.dart

import 'package:flutter/material.dart';
import '../models/stop.dart';

class StopListItem extends StatelessWidget {
  final Stop stop;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;

  const StopListItem({
    Key? key,
    required this.stop,
    this.onTap,
    this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(stop.name),
        subtitle: Text(stop.address),
        trailing: stop.completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onNavigate != null)
                    IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: onNavigate,
                      tooltip: 'Navigate',
                    ),
                  if (onTap != null)
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: onTap,
                      tooltip: 'Complete Stop',
                    ),
                ],
              ),
      ),
    );
  }
}
