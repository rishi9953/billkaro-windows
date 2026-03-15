  import 'package:billkaro/config/config.dart';

Widget footerSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('India Restaurant Billing App!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFB0B0B0), height: 1.3)),
          SizedBox(height: 8),
          Text('Crafted by Simply Bill Karo Chill Karo Pvt Ltd.', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }