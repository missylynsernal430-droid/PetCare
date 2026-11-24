class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
  });

  final String id;
  final String name;
  final String type;
  final int age;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'age': age,
  };

  factory Pet.fromMap(Map<String, Object?> map) => Pet(
    id: map['id']! as String,
    name: map['name']! as String,
    type: map['type']! as String,
    age: map['age']! as int,
  );
}
