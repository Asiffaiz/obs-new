class BusinessCard {
  final int? id;
  final String name;
  final String company;
  final String jobTitle;
  final String phoneNumber;
  final String email;
  final String? website;
  final String? address;
  final String? imagePath;
  final DateTime createdAt;

  BusinessCard({
    this.id,
    required this.name,
    required this.company,
    required this.jobTitle,
    required this.phoneNumber,
    required this.email,
    this.website,
    this.address,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'jobTitle': jobTitle,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'address': address,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BusinessCard.fromMap(Map<String, dynamic> map) {
    return BusinessCard(
      id: map['id'],
      name: map['name'],
      company: map['company'],
      jobTitle: map['jobTitle'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      website: map['website'],
      address: map['address'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  BusinessCard copyWith({
    int? id,
    String? name,
    String? company,
    String? jobTitle,
    String? phoneNumber,
    String? email,
    String? website,
    String? address,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return BusinessCard(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
