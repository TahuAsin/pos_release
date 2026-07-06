class CategoryModel {
  final int? id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    this.id,
    required this.name,
    this.color = '#1B3A8A',
    this.icon = 'category',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#1B3A8A',
      icon: map['icon'] as String? ?? 'category',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
