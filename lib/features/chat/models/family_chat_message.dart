class FamilyChatMessage {
  const FamilyChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.isAssistant = false,
  });

  final String id;
  final String author;
  final String text;
  final DateTime createdAt;
  final bool isAssistant;

  factory FamilyChatMessage.fromRow(Map<String, dynamic> row) =>
      FamilyChatMessage(
        id: row['id'] as String,
        author: row['author_name'] as String,
        text: row['message'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        isAssistant: row['is_assistant'] as bool? ?? false,
      );
}
