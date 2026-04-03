import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/glass_container.dart';
import '../chat/chat_view.dart';

class DiscoverView extends StatelessWidget {
  final UserController _userController = Get.put(UserController());
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();

  final List<String> passions = ['All', 'Coding', 'Music', 'Travel', 'Art', 'Fitness', 'Gaming'];
  final RxString _selectedPassion = 'All'.obs;

  DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildPassionFilter(),
          Expanded(
            child: Obx(() {
              if (_userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
              }
              if (_userController.usersList.isEmpty) {
                return const Center(child: Text('No matches found...', style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _userController.usersList.length,
                itemBuilder: (context, index) {
                  final user = _userController.usersList[index];
                  return _buildUserCard(user);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => _userController.fetchUsers(name: value, passion: _selectedPassion.value == 'All' ? null : _selectedPassion.value),
          decoration: InputDecoration(
            hintText: 'Search by name...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPassionFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: passions.length,
        itemBuilder: (context, index) {
          final passion = passions[index];
          return Obx(() {
            final isSelected = _selectedPassion.value == passion;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  _selectedPassion.value = passion;
                  _userController.fetchUsers(passion: passion == 'All' ? null : passion, name: _searchController.text.isEmpty ? null : _searchController.text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigoAccent : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(child: Text(passion, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold))),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.indigoAccent.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white70, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${user.age} years old', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(user.passion, style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.indigoAccent),
              onPressed: () => Get.to(() => ChatView(targetUser: user)),
            ),
          ],
        ),
      ),
    );
  }
}
