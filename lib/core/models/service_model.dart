class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String iconName;
  final int durationMinutes;
  final double price;
  final double rating;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconName,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
    required this.rating,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      iconName: json['iconName'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'durationMinutes': durationMinutes,
      'price': price,
      'isActive': isActive,
      'rating': rating,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? iconName,
    int? durationMinutes,
    double? price,
    bool? isActive,
    double? rating,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
    );
  }
}
