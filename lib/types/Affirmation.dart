class Affirmation {
  final String affirmation;

  Affirmation({required this.affirmation});

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(affirmation: json['affirmation']);
  }
}