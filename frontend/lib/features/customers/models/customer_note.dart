/// One internal, merchant-only note on a customer's timeline — never shown
/// to the customer, never sent anywhere external.
class CustomerNote {
  const CustomerNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory CustomerNote.fromJson(Map<String, dynamic> json) => CustomerNote(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );
}
