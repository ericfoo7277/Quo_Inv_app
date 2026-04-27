/// Customer / billable contact domain entity.
///
/// Plain immutable model, deliberately decoupled from any backend.
/// Repository implementations (mock, Supabase, etc.) translate to/from
/// this shape.
///
/// Schema: customers(id, user_id, name, company_name, phone, whatsapp_number,
///   email, billing_address, notes, is_archived, created_at, updated_at)
class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.userId,
    this.email,
    this.companyName,
    this.phone,
    this.whatsappNumber,
    this.billingAddress,
    this.notes,
    this.isArchived = false,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  final String name;
  final String? companyName;
  final String? phone;

  /// WhatsApp-specific number, may differ from [phone].
  final String? whatsappNumber;

  final String? email;
  final String? billingAddress;
  final String? notes;
  final bool isArchived;

  /// URL of the customer's avatar / logo in storage.
  final String? avatarUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? companyName,
    String? phone,
    String? whatsappNumber,
    String? email,
    String? billingAddress,
    String? notes,
    bool? isArchived,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
