import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/payment.dart';
import 'package:real_galaxy/models/player.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:intl/intl.dart';

class PaymentStatusScreen extends StatefulWidget {
  final Role userRole;
  final String userId;

  const PaymentStatusScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Player> _players = [];
  final Map<String, List<Payment>> _playerPayments = {};
  final Map<String, String> _parentNames = {};
  bool _isLoading = true;
  String _filter = 'all';

  Future<List<User>> _getAllUsers() async {
    final users = <User>[];
    try {
      final snapshot = await _firebaseService.usersRef.get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          users.add(
            User(
              id: child.key ?? '',
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              password: '',
              role: RoleExtension.fromString(data['role'] ?? 'parent'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    return users;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check if user is authenticated before proceeding
    final authService = AuthService();
    final currentUser = await authService.getCurrentUserProfile();
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Please sign in to view payment status', Colors.red);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      _players = await _firebaseService.getAllPlayers();

      final payments = await _firebaseService.getAllPayments();
      for (var payment in payments) {
        if (payment.playerId.isNotEmpty) {
          _playerPayments[payment.playerId] ??= [];
          _playerPayments[payment.playerId]!.add(payment);
        }
      }

      final playerList = await _firebaseService.getAllPlayers();
      for (var player in playerList) {
        if (player.parentId.isNotEmpty) {
          final parentProfile = await _firebaseService.getUserProfile(
            player.parentId,
          );
          if (parentProfile != null) {
            _parentNames[player.parentId] = parentProfile.name;
          }
        }
      }
    } catch (e) {
      print('Error loading payment data: $e');
    }
    setState(() => _isLoading = false);
  }

  PaymentStatus? getPaymentStatus(String playerId) {
    final payments = _playerPayments[playerId];
    if (payments == null || payments.isEmpty) return null;

    final latest = payments.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    return latest.status;
  }

  String getParentName(String? parentId) {
    if (parentId == null || parentId.isEmpty) return 'N/A';
    return _parentNames[parentId] ?? 'Parent Not Found';
  }

  List<Player> get filteredPlayers {
    switch (_filter) {
      case 'paid':
        return _players
            .where((p) => getPaymentStatus(p.id!) == PaymentStatus.paid)
            .toList();
      case 'pending':
        return _players
            .where((p) => getPaymentStatus(p.id!) == PaymentStatus.pending)
            .toList();
      case 'unpaid':
        return _players.where((p) => getPaymentStatus(p.id!) == null).toList();
      default:
        return _players;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Payment Status'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onBackgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Paid', 'paid'),
                      _buildFilterChip('Pending', 'pending'),
                      _buildFilterChip('Unpaid', 'unpaid'),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredPlayers.isEmpty
                      ? const Center(
                          child: Text(
                            'No players found',
                            style: TextStyle(color: AppTheme.onBackgroundSubtle),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredPlayers.length,
                          itemBuilder: (context, index) {
                            final player = filteredPlayers[index];
                            final status = getPaymentStatus(player.id!);

                            return Card(
                              color: AppTheme.surfaceColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(status),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: AppTheme.onBackgroundColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  player.name,
                                  style: const TextStyle(
                                    color: AppTheme.onBackgroundColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Parent: ${getParentName(player.parentId)}',
                                      style: const TextStyle(
                                        color: AppTheme.onBackgroundSubtle,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Position: ${player.position ?? "Not set"} | Age: ${player.age}',
                                      style: const TextStyle(
                                        color: AppTheme.onBackgroundFaint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusLabel(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () => _showPaymentDetails(player),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.outlineColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.onBackgroundColor : AppTheme.onBackgroundSubtle,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus? status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PaymentStatus? status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.access_time;
      default:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(PaymentStatus? status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      default:
        return 'Unpaid';
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showPaymentDetails(Player player) {
    final payments = _playerPayments[player.id] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(player.name, style: const TextStyle(color: AppTheme.onBackgroundColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: payments.isEmpty
              ? const Text(
                  'No payment records',
                  style: TextStyle(color: AppTheme.onBackgroundSubtle),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      color: AppTheme.surfaceVariantColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          '${payment.paymentType.name.toUpperCase()} - ₵${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppTheme.onBackgroundColor),
                        ),
                        subtitle: Text(
                          'Status: ${payment.statusDisplay}',
                          style: TextStyle(
                            color: _getStatusColor(payment.status),
                          ),
                        ),
                        trailing: Text(
                          payment.paidAt != null
                              ? DateFormat('MMM dd').format(payment.paidAt!)
                              : '',
                          style: const TextStyle(
                            color: AppTheme.onBackgroundFaint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

