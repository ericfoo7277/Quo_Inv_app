/// Customer / billable contact domain entity.
///
/// Plain immutable model, deliberately decoupled from any backend.
/// Repository implementations (mock, Supabase, etc.) translate to/from
/// this shape.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.company,
    this.phone,
    this.address,
    this.taxId,
    this.notes,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? company;
  final String? phone;
  final String? address;
  final String? taxId;
  final String? notes;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? company,
    String? phone,
    String? address,
    String? taxId,
    String? notes,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
