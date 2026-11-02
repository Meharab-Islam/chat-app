class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String status;
  final String bio;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.status = '',
    this.bio = '',
    this.isOnline = false,
    this.lastSeen,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? status,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'status': status,
    'bio': bio,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'User',
    email: json['email'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    status: json['status'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    isOnline: json['isOnline'] as bool? ?? false,
    lastSeen: json['lastSeen'] != null
        ? DateTime.tryParse(json['lastSeen'] as String)
        : null,
  );
}
