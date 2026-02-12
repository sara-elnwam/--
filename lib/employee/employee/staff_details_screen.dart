import 'package:flutter/material.dart';

class StaffDetailsScreen extends StatelessWidget {
  final int staffId;
  final String staffName;

  const StaffDetailsScreen({super.key, required this.staffId, required this.staffName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(staffName, style: const TextStyle(fontFamily: 'Almarai')),
        backgroundColor: const Color(0xFF07427C),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 100, color: Color(0xFF07427C)),
            const SizedBox(height: 20),
            Text("رقم الموظف: $staffId", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("اسم الموظف: $staffName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}