class UserModel {
  final String id;
  final String name;
  final String email;
  final int age;
  final String passion;
  final List<String> interests;
  final String profileImage;
  final String status;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.passion,
    required this.interests,
    this.profileImage = '',
    this.status = 'Offline',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      passion: json['passion'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      profileImage: json['profileImage'] ?? '',
      status: json['status'] ?? 'Offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'passion': passion,
      'interests': interests,
      'profileImage': profileImage,
      'status': status,
    };
  }
}
