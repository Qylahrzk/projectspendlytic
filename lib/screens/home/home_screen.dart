import 'package:flutter/material.dart';
import '../../services/db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'User';
  String userEmail = '';
  String? photoUrl;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await DBService().getUserData();

    setState(() {
      userName = userData?['name'] ?? 'User';
      userEmail = userData?['email'] ?? '';
      photoUrl = null; // you can use photoUrl if saved
    });
  }

  Future<void> _logout() async {
    await DBService().clearUserData();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
    // Add navigation handling here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildCategoryRow(),
            _buildExpenseList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6C63FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      width: double.infinity,
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: photoUrl != null
                ? NetworkImage(photoUrl!)
                : const AssetImage('assets/images/profile.jpg') as ImageProvider,
            radius: 30,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 3,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total balance',
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              SizedBox(height: 8),
              Text('\$ 415.38',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _categoryIcon(Icons.coffee, 'Coffee'),
              _categoryIcon(Icons.shopping_bag, 'Shopping'),
              _categoryIcon(Icons.card_giftcard, 'Gifts'),
              _categoryIcon(Icons.medication, 'Health'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple.shade50,
          child: Icon(icon, color: Colors.deepPurple),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildExpenseList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _expenseTile('McDonald\'s', 'Restaurants', '-\$14.76',
              'assets/images/mcd.png'),
          _expenseTile('H&M', 'Shopping', '-\$50.76', 'assets/images/hm.png'),
          _expenseTile('ZARA', 'Shopping', '-\$60.87', 'assets/images/zara.png'),
        ],
      ),
    );
  }

  Widget _expenseTile(String name, String category, String amount, String iconPath) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Image.asset(iconPath, height: 36),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(category),
      trailing: Text(amount, style: const TextStyle(color: Colors.red)),
    );
  }
}
