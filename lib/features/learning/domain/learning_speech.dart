import 'learning_models.dart';

/// Lowercase a/i must be read as letter names, not an article or pronoun.
String learningLetterName(LearningItem item) =>
    item.subject == 'english' ? item.name.toUpperCase() : item.name;

String learningListeningText(LearningItem item) =>
    '${learningLetterName(item)}. ${item.example}.';
